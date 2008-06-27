# Test the following topology with one TCP flow
# node h0 and sink on node h2
#
# Topology:
# N: # of nodes
# 
# TCP flow 
# n0 -----> n(N-1)
# 

proc check_globe_data { path file_name } {
	if { ! [file exist "$path/globe.dat" ] || ! [ file exist "$path/$file_name" ] } {
		puts "ERROR:"
		puts "You do not install the GLOBE database or put them in the right place"
		puts "To install GLOBE database:"
		puts "1. Create a directory at $path"
		puts "2. Make sure the directory contains a file globe.dat, which is contained in this package"
		puts "3. Download the file $file_name.tgz from ftp://ftp.ngdc.noaa.gov/GLOBE_DEM/data/elev/$file_name.tgz"
		puts "   or from the website http://www.ngdc.noaa.gov/seg/topo/gltiles.shtml"
		puts "4. Extract the downloaded file to $path"
		puts "This script only uses data from the file $file_name.tgz. If your application"
		puts "may require to access elevation data in other files, you will need to download"
	    puts "all 16 tiles of data from the above website and extract them to $path."
		puts "You may also change the directory that contains the GLOBE data, "
		puts "which is specified  by \$globe_path in this script." 
		exit
	}
}

cd [mkdir -q drcl.comp.Component /aodvtest]

set N  20 
set maxX  -117.138245 
set minX  -117.245674 
set maxY  34.857337
set minY  32.496198  
set dX	  0.0025 
set dY 	  0.0025 	;  	#the above in the unit of degree
set dZ    1000   	;	#in the unit of meter

puts "create channel"

mkdir drcl.inet.mac.Channel channel

mkdir drcl.inet.mac.NodePositionTracker tracker 
#                 maxX    minX  maxY    minY   dX      dY
! tracker setGrid $maxX    $minX  $maxY    $minY   $dX      $dY


connect channel/.tracker@ -and tracker/.channel@
! channel setCapacity [expr $N]

# create the topology
puts "create topology..."

for {set i 0} {$i < $N} {incr i} { 
	puts "create node $i"
	set node$i [mkdir drcl.comp.Component n$i]
	
	cd n$i

	mkdir drcl.inet.mac.LL              ll
	mkdir drcl.inet.mac.ARP             arp
    mkdir drcl.inet.core.queue.PreemptPriorityQueue     queue
	mkdir drcl.inet.mac.Mac_802_11      mac
	mkdir drcl.inet.mac.WirelessPhy     phy
	mkdir drcl.inet.mac.IrregularTerrainModel	propagation 
	mkdir drcl.inet.mac.MobilityModel   mobility

	#set ITM parameters, the first is required, all remaining are optional.   
	# you must set this path to the directory that contains Globe data files.
	set globe_path "./globedat/"
	check_globe_data $globe_path e10g
	! propagation setGlobePath   $globe_path
	# The values set below are default values for each value
	! propagation setNumPoints  20
	! propagation setPolarity   1
	! propagation setRadioClimate 4
	! propagation setSurfRef	280	
	! propagation setDielectric 15.0 
	! propagation setConductivity 0.005 

	
	#set two level in Priority queue
	! queue setLevels 2
	! queue setClassifier [java::new drcl.inet.mac.MacPktClassifier]
     
        set PD [mkdir drcl.inet.core.PktDispatcher      pktdispatcher]
        set RT [mkdir drcl.inet.core.RT                 rt]
        set ID [mkdir drcl.inet.core.Identity           id]
 
        $PD bind $RT
        $PD bind $ID	

	#enable route_back flag at PktDispatcher
	! pktdispatcher setRouteBackEnabled true

	mkdir drcl.inet.protocol.aodv.AODV  aodv
	connect -c aodv/down@ -and pktdispatcher/103@up
	connect aodv/.service_rt@ -and rt/.service_rt@
	connect aodv/.service_id@ -and id/.service_id@
	connect aodv/.ucastquery@ -and pktdispatcher/.ucastquery@
	connect mac/.linkbroken@ -and aodv/.linkbroken@

	# present if using 802.11 power-saving mode
	#connect mac/.energy@ -and phy/.energy@ 
	#! mac enable_PSM 
	! mac disable_PSM 

	# since 802.11 provides link broken detection, we set the flag in AODV
        # no hello and nbr timer will be used
        ! aodv enable_link_detection

#	puts "connect components in node $i"
	
	connect phy/.mobility@    -and mobility/.query@
	connect phy/.propagation@ -and propagation/.query@
	
	connect mac/down@ -and phy/up@
	connect mac/up@   -and queue/output@
	
	connect ll/.mac@ -and mac/.linklayer@
	connect ll/down@ -and queue/up@ 
	connect ll/.arp@ -and arp/.arp@
	
	connect -c pktdispatcher/0@down -and ll/up@   
	 
	set nid $i
	
	! arp setAddresses  $nid $nid
	! ll  setAddresses  $nid $nid
	! mac setMacAddress $nid
	! phy setNid        $nid
	! mobility setNid   $nid
	! id setDefaultID   $nid

	! queue setMode      "packet"
	! queue setCapacity  40

# disable ARP 
	! arp setBypassARP  true
	
	! mac setRTSThreshold 0
	
	connect mobility/.report@ -and /aodvtest/tracker/.node@

	connect phy/down@ -to /aodvtest/channel/.node@

	! /aodvtest/channel attachPort $i [! phy getPort .channel]

	# design a scenario that all nodes are aligned and require multi-hops routing

    ! mobility setPosition 0.0 [expr $minX +   0.001 * $i] [expr ($minY + $maxY) / 2]  0.0  


	
#                                     maxX    minX  maxY    minY    dX     dY    dZ
    ! mobility setTopologyParameters  $maxX    $minX  $maxY    $minY    $dX     $dY    $dZ
    

	! mac  disable_MAC_TRACE_ALL
	
	! mac set_MAC_TRACE_ALL_ENABLED     false
	! mac set_MAC_TRACE_PACKET_ENABLED  false
	! mac set_MAC_TRACE_CW_ENABLED      false
	! mac set_MAC_TRACE_EVENT_ENABLED   false
	! mac set_MAC_TRACE_TIMER_ENABLED   false

	cd ..

}


puts "setup source and sink..."

mkdir drcl.inet.transport.TCP n0/tcp
connect -c n0/tcp/down@ -and n0/pktdispatcher/17@up
! n0/tcp setMSS  512;                       # bytes
! n0/tcp setPeer 19

set src_ [mkdir drcl.inet.application.BulkSource n0/source]
$src_ setDataUnit 512
connect -c $src_/down@ -and n0/tcp/up@


mkdir drcl.inet.transport.TCPSink n19/tcpsink
connect -c n19/tcpsink/down@ -and n19/pktdispatcher/17@up
set sink_ [mkdir drcl.inet.application.BulkSink n19/sink]
connect -c $sink_/down@ -and n19/tcpsink/up@

puts "Set up TrafficMonitor & Plotter..."
set plot_ [mkdir drcl.comp.tool.Plotter .plot]
set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm]

connect -c n19/pktdispatcher/tcp@up -to $tm_/in@
connect -c $tm_/bytecount@ -to $plot_/0@0
connect -c n0/tcp/cwnd@ -to $plot_/0@1
connect -c n19/tcpsink/seqno@ -to $plot_/0@2
# connect -c n0/tcp/srtt@ -to $plot_/0@3


set fileName_ aodv_n20_tcp1_traceall.result
puts "Set up file '$fileName_' to store rsults..."
set file_ [mkdir drcl.comp.io.FileComponent .file]
$file_ open $fileName_
connect -c n0/propagation/.proptrace@ -to $file_/in@
connect -c n19/propagation/.proptrace@ -to $file_/in@





connect -c [! /.term/tcl0/result@] -to $file_/in@

# Simple procedure to inject data at node0/csl/100@up
proc send data_ {
        set source_ 0
        set destination_ 1
        set routerAlert_ false
        set TTL_ 1
        set ToS_ 0
        set size_ 100
        set packet_ [java::call drcl.inet.contract.PktSending getForwardPack $data_ $size_ $source_ $destination_ $routerAlert_ $TTL_ $ToS_]
        inject $packet_ node0/csl/100@up
}




puts "simulation begins..."	
set sim [attach_simulator .]
$sim stop

! n0/mac enable_MAC_TRACE_ALL
! n19/mac enable_MAC_TRACE_ALL
script {run n1} -at 0.02 -on $sim
script {run n2} -at 0.04 -on $sim
script {run n3} -at 0.06 -on $sim
script {run n4} -at 0.08 -on $sim
script {run n5} -at 0.10 -on $sim
script {run n6} -at 0.12 -on $sim
script {run n7} -at 0.14 -on $sim
script {run n8} -at 0.16 -on $sim
script {run n9} -at 0.18 -on $sim
script {run n10} -at 0.20 -on $sim
script {run n11} -at 0.22 -on $sim
script {run n12} -at 0.24 -on $sim
script {run n13} -at 0.26 -on $sim
script {run n14} -at 0.28 -on $sim
script {run n15} -at 0.30 -on $sim
script {run n16} -at 0.32 -on $sim
script {run n17} -at 0.34 -on $sim
script {run n18} -at 0.36 -on $sim

script {run n19} -at 2.0 -on $sim
script {run n0}  -at 5.0 -on $sim
$sim resume
$sim stopAt 300.0 
