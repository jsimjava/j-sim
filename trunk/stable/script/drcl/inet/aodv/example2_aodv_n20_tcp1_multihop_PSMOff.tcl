# Test the following topology with one TCP flow
# node h0 and sink on node h2
#
# Topology:
# N: # of nodes
# 
# TCP flow 
# n0 -----> n(N-1)
# 

source "../../../test/include.tcl"

cd [mkdir -q drcl.comp.Component /aodvtest]

set N  20

puts "create channel"

mkdir drcl.inet.mac.Channel channel

mkdir drcl.inet.mac.NodePositionTracker tracker 
#                 maxX    minX  maxY    minY   dX      dY
! tracker setGrid 2000.0  0.0   2000.0  0.0    300.0  300.0

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
	#mkdir drcl.inet.core.queue.FIFO     queue
	#mkdir drcl.inet.core.queue.PriorityQueue     queue
        mkdir drcl.inet.core.queue.PreemptPriorityQueue     queue
	mkdir drcl.inet.mac.Mac_802_11      mac
	mkdir drcl.inet.mac.WirelessPhy     phy
	mkdir drcl.inet.mac.FreeSpaceModel  propagation 
	mkdir drcl.inet.mac.MobilityModel   mobility

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

        ! mac setDebugEnabled false
	
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
#    ! mobility setPosition 1.0 [expr 10 + rand()*1900] [expr 10 + rand()*1900]  0.0
#    ! mobility setPosition 0.0 [expr 10.0 * $i] 0.0  0.0  
#    ! mobility setPosition 0.0 [expr 100.0 * $i] 0.0  0.0

    ! mobility setPosition 0.0 [expr 80.0 * $i] 0.0  0.0  


	
#                                     maxX    minX  maxY    minY    dX     dY    dZ
    ! mobility setTopologyParameters  2000.0  0.0   2000.0  0.0    300.0  300.0  0.0
    

	! mac  disable_MAC_TRACE_ALL
	
	! mac set_MAC_TRACE_ALL_ENABLED     false
	! mac set_MAC_TRACE_PACKET_ENABLED  false
	! mac set_MAC_TRACE_CW_ENABLED      false
	! mac set_MAC_TRACE_EVENT_ENABLED   false
	! mac set_MAC_TRACE_TIMER_ENABLED   false

	cd ..

}

#script {! n0/mac      setDebugEnabled true} -at 11.0 -on $sim
#! n0/mac      setDebugEnabled true


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

###set stdout [mkdir drcl.comp.io.Stdout .stdout]
###set pstdout [mkdir $stdout/in@]
###for {set i 0} {$i < $N2} {incr i} { 
###	connect n$i/mac/.mactrace@ -to $pstdout
###}

if { $testflag } {
	attach -c $testfile/in@ -to $tm_/bytecount@ 
	attach -c $testfile/in@ -to n0/tcp/cwnd@
	attach -c $testfile/in@ -to n19/tcpsink/seqno@ 
	attach -c $testfile/in@ -to n0/tcp/srtt@
	attach -c $testfile/in@ -to n0/mac/.mactrace@

} else {
	set fileName_ aodv_n20_tcp1_traceall.result
	puts "Set up file '$fileName_' to store rsults..."
	set file_ [mkdir drcl.comp.io.FileComponent .file]
	$file_ open $fileName_
	connect -c n0/mac/.mactrace@ -to $file_/in@
}


#set fileName_ mac0_debug.result
#puts "Set up file '$fileName_' to store rsults..."
#set file2_ [mkdir drcl.comp.io.FileComponent .file2]
#$file2_ open $fileName_
#connect -c n0/mac/.info@ -to $file2_/in@



#####connect -c [! /.term/tcl0/result@] -to $file_/in@

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
set sim [attach_simulator event .]
$sim stop

#setflag trace true n0/mac/down@
#setflag debug true n0/ll
#setflag trace true n3/ll/down@
#setflag trace true n2/pktdispatcher/0@down
#setflag trace true n1/pktdispatcher/0@down
#setflag trace true n0/mac
#setflag trace true n1/mac
#setflag trace true n2/mac
#setflag trace true n3/mac
#setflag trace true n0/phy
#setflag trace true n1/phy
#setflag trace true n2/phy
#setflag trace true n3/phy
#setflag trace true channel
#setflag debug true n0/tcp
#setflag debug true n19/tcpsink
#setflag debug true n4/tcpsink
#setflag debug true n5/tcpsink
#setflag debug true -at "rreq rrep rerr send hello data route" n*/aodv
#setflag debug true -at "rreq rrep rerr " n*/aodv
#setflag trace false n*/mac

#script {setflag debug true -at "rreq rrep rerr send hello data route" n*/aodv} -at 15.0 -on $sim
#script {setflag trace true n0/pktdispatcher/103@up} -at 58.0 -on $sim
#script {setflag trace true n0/pktdispatcher/0@down} -at 58.0 -on $sim
#script {setflag trace true n0/ll} -at 58.0 -on $sim
#script {setflag trace true n0/queue} -at 58.0 -on $sim
#script {setflag trace true n0/mac} -at 58.0 -on $sim
#script {setflag trace true n0/phy} -at 58.0 -on $sim
#script {setflag trace true n1/phy} -at 58.0 -on $sim
#setflag debug true -at "rerr " n*/aodv
#setflag garbagedisplay true .../q*

#! n0/mac enable_MAC_TRACE_ALL
#! n0/mac enable_MAC_TRACE_EVENT; 
#! n0/mac enable_MAC_TRACE_PACKET;
#! n0/mac disable_MAC_TRACE_CW;
#! n0/mac disable_MAC_TRACE_TIMER;

#setflag trace true n0/ll/up@
#setflag trace true n0/ll/down@
#setflag trace true n19/ll/up@

# need to start different pairs of TCP connections at different time
# in order to avoid route request collision
#for {set i 1} {$i < [expr $N - 1]} {incr i} { 
#	script {run n$i} -at [expr 0.02 * $i] -on $sim
#}	
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

#script {! n0/mac      setDebugEnabled true} -at 11.50 -on $sim

script {run n19} -at 2.0 -on $sim
script {run n0}  -at 5.0 -on $sim

$sim resumeTo 300.0 
