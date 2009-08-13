# Test inet in following topology with TCP source on
# node h0 and sink on node h2
#
# Topology:
# N: (# of nodes)/2
# ni ----- n(i+N)
# 

source "../../../test/include.tcl"

cd [mkdir -q drcl.comp.Component /aodvtest]

set N  3
set N2 6

puts "create channel"

mkdir drcl.inet.mac.Channel channel

mkdir drcl.inet.mac.NodePositionTracker tracker 
#                 maxX   minX  maxY   minY   dX    dY
! tracker setGrid 100.0  0.0   100.0  0.0    60.0  60.0

connect channel/.tracker@ -and tracker/.channel@
! channel setCapacity [expr $N+$N]

# create the topology
puts "create topology..."

for {set i 0} {$i < $N2} {incr i} { 
#	puts "create node $i"
	set node$i [mkdir drcl.comp.Component n$i]
	
	cd n$i

	mkdir drcl.inet.mac.LL              ll
	mkdir drcl.inet.mac.ARP             arp
	mkdir drcl.inet.core.queue.FIFO     queue
	mkdir drcl.inet.mac.Mac_802_11      mac
	mkdir drcl.inet.mac.WirelessPhy     phy
	mkdir drcl.inet.mac.FreeSpaceModel  propagation 
	mkdir drcl.inet.mac.MobilityModel   mobility
	     
	set PD [mkdir drcl.inet.core.PktDispatcher      pktdispatcher]
        set RT [mkdir drcl.inet.core.RT                 rt]
        set ID [mkdir drcl.inet.core.Identity           id]
 
        $PD bind $RT
        $PD bind $ID

        ! pktdispatcher setRouteBackEnabled true

	mkdir drcl.inet.protocol.aodv.AODV  aodv
	connect -c aodv/down@ -and pktdispatcher/103@up
	connect aodv/.service_rt@ -and rt/.service_rt@
	connect aodv/.service_id@ -and id/.service_id@
	connect aodv/.ucastquery@ -and pktdispatcher/.ucastquery@
	connect mac/.linkbroken@ -and aodv/.linkbroken@

	# present if using 802.11 power-saving mode
        connect mac/.energy@ -and phy/.energy@

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
	! arp setBypassARP  [ expr 2>1]
	
	! mac setRTSThreshold 0
	
	connect mobility/.report@ -and /aodvtest/tracker/.node@

	connect phy/down@ -to /aodvtest/channel/.node@

	! /aodvtest/channel attachPort $i [! phy getPort .channel]


    ! mobility setPosition 00.0 0.0 0.0 0.0
#                                     maxX   minX  maxY   minY   dX    dY    dZ
    ! mobility setTopologyParameters  100.0  0.0   100.0  0.0    60.0  60.0  0.0
    

	! mac  disable_MAC_TRACE_ALL

        ! mac set_MAC_TRACE_ALL_ENABLED     false
        ! mac set_MAC_TRACE_PACKET_ENABLED  false
        ! mac set_MAC_TRACE_CW_ENABLED      false
        ! mac set_MAC_TRACE_EVENT_ENABLED   false
        ! mac set_MAC_TRACE_TIMER_ENABLED   false
	
	cd ..

}

puts "setup source and sink..."

for {set i 0} {$i < $N} {incr i} { 
	mkdir drcl.inet.transport.TCP n$i/tcp
	connect -c n$i/tcp/down@ -and n$i/pktdispatcher/17@up
	! n$i/tcp setMSS  512;                       # bytes
	! n$i/tcp setPeer [expr $i+$N]

	set src_ [mkdir drcl.inet.application.BulkSource n$i/source]
	$src_ setDataUnit 512
	connect -c $src_/down@ -and n$i/tcp/up@

}

for {set i $N} {$i < $N2} {incr i} { 
	mkdir drcl.inet.transport.TCPSink n$i/tcpsink
	connect -c n$i/tcpsink/down@ -and n$i/pktdispatcher/17@up
	
	set sink_ [mkdir drcl.inet.application.BulkSink n$i/sink]
	connect -c $sink_/down@ -and n$i/tcpsink/up@
}




puts "Set up TrafficMonitor & Plotter..."
set plot_ [mkdir drcl.comp.tool.Plotter .plot]
set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm]
connect -c n$N/pktdispatcher/tcp@up -to $tm_/in@
connect -c $tm_/bytecount@ -to $plot_/0@0
connect -c n0/tcp/cwnd@ -to $plot_/0@1
connect -c n$N/tcpsink/seqno@ -to $plot_/0@2
connect -c n0/tcp/srtt@ -to $plot_/0@3


if { $testflag } {
	attach -c $testfile/in@ -to $tm_/bytecount@
	attach -c $testfile/in@ -to n0/tcp/cwnd@ 
	attach -c $testfile/in@ -to n$N/tcpsink/seqno@ 
	attach -c $testfile/in@ -to n0/tcp/srtt@ -to 
	attach -c $testfile/in@ -to n0/mac/.mactrace@
} else {
	set stdout [mkdir drcl.comp.io.Stdout .stdout]
	set pstdout [mkdir $stdout/in@]
	for {set i 0} {$i < $N2} {incr i} { 
		connect n$i/mac/.mactrace@ -to $pstdout
	}

	set fileName_ tcp6nodes_traceall.result
	puts "Set up file '$fileName_' to store rsults..."
	set file_ [mkdir drcl.comp.io.FileComponent .file]
	$file_ open $fileName_
	connect -c n0/mac/.mactrace@ -to $file_/in@
}

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

#setflag garbagedisplay true .../q*
# ! n0/mac  enable_MAC_TRACE_ALL
#setflag trace true n0/mac/down@
#setflag debug true n0/ll
#setflag trace true n0/ll/down@
#setflag trace true n0/mac
#setflag trace true n1/mac
#setflag trace true n0/phy
#setflag trace true n1/phy
#setflag trace true channel
#setflag debug true n2/tcp
#setflag debug true n5/tcpsink
#setflag debug true -at "rreq rrep rerr data" n*/aodv
#setflag debug true -at "rerr" n*/aodv
#setflag debug true -at "rerr" n*/aodv

# need to start different pairs of TCP connections at different time
# in order to avoid route request collision
script {run n5} -at 0.0 -on $sim
script {run n4} -at 0.1 -on $sim
script {run n3} -at 0.2 -on $sim
script {run n2} -at 0.3 -on $sim
script {run n1} -at 0.4 -on $sim
script {run n0} -at 0.5 -on $sim

$sim resumeTo 100.0 
