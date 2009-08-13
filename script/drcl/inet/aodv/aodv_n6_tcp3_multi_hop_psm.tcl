# Test the following topology with N pairs of TCP source and sink
#
# Topology:
# N: (# of nodes)/2
#
# TCP flow from  ni -----> n(i+N)
# 

source "../../../test/include.tcl"

cd [mkdir -q drcl.comp.Component /aodvtest]

set N  3
set N2 6

puts "create channel"

mkdir drcl.inet.mac.Channel channel

mkdir drcl.inet.mac.NodePositionTracker tracker 
#                 maxX    minX  maxY    minY   dX      dY
! tracker setGrid 2000.0  0.0   2000.0  0.0    300.0  300.0

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
	connect mac/.energy@ -and phy/.energy@ 
	! mac enable_PSM 
	#! mac disable_PSM 
	
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
	set hop_dist	200
	! mobility setPosition 0.0 [expr $i * $hop_dist] 500.0 0.0
	
#                                         maxX    minX  maxY    minY    dX     dY    dZ
	! mobility setTopologyParameters  2000.0  0.0   2000.0  0.0    300.0  300.0  0.0
    

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
connect -c n2/tcp/srtt@ -to $plot_/0@3
connect -c n1/tcp/cwnd@ -to $plot_/0@4
connect -c n2/tcp/cwnd@ -to $plot_/0@5

if { $testflag } {
	attach -c $testfile/in@ -to $tm_/bytecount@ 
	attach -c $testfile/in@ -to n0/tcp/cwnd@
	attach -c $testfile/in@ -to n$N/tcpsink/seqno@ 
	attach -c $testfile/in@ -to n2/tcp/srtt@
	attach -c $testfile/in@ -to n1/tcp/cwnd@
	attach -c $testfile/in@ -to n2/tcp/cwnd@
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
#setflag trace true n0/mac/down@
#setflag debug true n0/ll
#setflag trace true n3/ll/down@
#setflag trace true n2/pktdispatcher/0@down
#setflag trace true n0/pktdispatcher/0@down
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
#setflag debug true n0/tcp
#setflag debug true n4/tcpsink
#setflag debug true n5/tcpsink
#setflag debug true -at "rreq rrep rerr send hello data route" n*/aodv
#setflag debug true -at "rreq rrep rerr " n*/aodv
#setflag trace false n*/mac
#setflag debug true -at "rerr " n*/aodv
#setflag garbagedisplay true .../q*
# ! n0/mac  enable_MAC_TRACE_ALL

#script {setflag trace true recursively n*} -at 4.0 -on $sim
#script {setflag trace true n*/phy/down@} -at 4.0 -on $sim

# need to start different pairs of TCP connections at different time
# in order to avoid route request collision
for {set i 0} {$i < $N2} {incr i} {
        script "run n$i" -at [expr 0.5 * [expr $N2 - $i]] -on $sim
}

$sim resumeTo 100.0 
