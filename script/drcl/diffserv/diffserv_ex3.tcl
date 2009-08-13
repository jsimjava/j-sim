# diffserv_ex3.tcl
#
# Topology:
# h3 ---\                   /--- h6
#        \                 /
# h4 ----- n1 --- n0 ---- n2 ----- h7
#        /(edge) (core)    \
# h5 ---/                   \--- h8
#
# (1) h3-h6, h4-h7:
#     tcp/bulk transfer connections
#     tagged as "AF_11" at sender
#     TC_meter at edge n1, h4-h7 has twice reservation as h3-h6
#     
# (2) h5-h8:
#     CBR at 1.2e5 bps
#     tagged as "EF" at sender
#     TB_meter at edge n1
#
# (3) core router n0 is equipped with a priority queue:
#     For EF and best-efforts: droptail
#     For AF: wrr (AF1x and AF2x: droptail/3ColorQueue)

set bandwidth 1.0e6; # bps
set propDelay 0.05;   # second
set port 1001; # for CBR traffic

set toSetupCBR 1
set toSetupHostTC 1
set toSetupEdgeTC 1
set toSetupCoreQ 1
set toSetupPlot 1
set toSetupPlotFile 0
set toSetupInspect 0

cd [mkdir -q drcl.comp.Component /example3]

# create the topology
puts "create topology..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay $propDelay; # 50ms
set adjMatrix_ [java::new {int[][]} 9 {{1 2} {0 3 4 5} {0 6 7 8} {1} {1} {1} {2} {2} {2}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "create builders..."

# CSLBuilder:
set ccb [mkdir drcl.inet.core.CSLBuilder .cslBuilder]
set ecb [cp $ccb .edgeRouterCSLBuilder]
set hcb [cp $ccb .hostCSLBuilder]

if $toSetupCoreQ {
	# set up CSL builder for core router
	mkdir drcl.diffserv.scheduling.pq $ccb/q1; # only at interface 1
}
if $toSetupEdgeTC {
	# set up CSL builder for edge router
	mkdir drcl.diffserv.TrafficConditioner $ecb/pf0_0; # only at interface 0
}
if $toSetupHostTC {
	# set up CSL builder for source host (containing marker)
	mkdir drcl.diffserv.TrafficConditioner $hcb/pf0_0;
}

# regular node builder:
set nb [mkdir drcl.inet.NodeBuilder .routerBuilder]
$nb setBandwidth 100.0e6; # 100Mbps

puts "build..."
$nb build [! n0] $ccb
$nb build [! n1] $ecb
$nb build [! n2,h8]
$nb build [! h5] $hcb
$nb build [! h3-4] $hcb {
	tcp 				drcl.inet.transport.TCP
	source 	-/tcp 		drcl.inet.application.BulkSource
}
$nb build [! h6-7] {
	tcpsink 			drcl.inet.transport.TCPSink
	sink 	-/tcpsink 	drcl.inet.application.BulkSink
}
! h3-4,h6-7/tcp* setMSS 512; #byte
! h3-4,h6-7/s* setDataUnit 512

#set cbr source
if $toSetupCBR {
# Arguments: pkt_size interval, rate 1.2e05 bps
	set traffic [java::new drcl.net.traffic.traffic_PacketTrain 150 0.01]; 
	java::call drcl.inet.InetUtil createTrafficSource $traffic "source" [! h5] [! h8] 0 $port
}

# Configure the bottleneck bandwidth and buffer size
! n0 setBandwidth 1 $bandwidth

# setup TCP parameters
! h3/tcp setPeer 6
! h4/tcp setPeer 7

puts "setup static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h3] [! h6] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h4] [! h7] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h5] [! h8] "bidirection"

if {$toSetupPlot | $toSetupPlotFile} {
puts "Set up TrafficMonitor & Plotter..."
set plot_ [mkdir drcl.comp.tool.Plotter .plot]
if {!$toSetupPlot} {
	set fileName_ "ex2.plot"
	puts "Set up file '$fileName_' to store results..."
	setflag plot false $plot_
	set file_ [mkdir drcl.comp.io.FileComponent .file]
	$file_ open $fileName_
	connect -c $plot_/.output@ -to $file_/in@
}
foreach i {6 7} {
	set j [expr $i-6]
	set k [expr $i-3]
	set tm$k\_ [mkdir drcl.net.tool.TrafficMonitor .tm$k]
	connect -c h$i/csl/6@up -to .tm$k/in@
	connect -c .tm$k/bytecount@ -to $plot_/$j@0
	connect -c h$k/tcp/cwnd@ -to $plot_/$j@1

}
! .tm? configure 4.0 0.5; # window size, update interval

foreach i {8} {
	set j [expr $i-6]
	set k [expr $i-3]
	set tm$k\_ [mkdir drcl.net.tool.TrafficMonitor .tm$k]
	connect -c h$i/csl/$port@up -to .tm$k/in@
	connect -c .tm$k/bytecount@ -to $plot_/$j@0
}
if $toSetupInspect {
setflag inspection true n1/csl/pf0_0
foreach i {3 4} {
	set j [expr $i-1]
	set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm$i\_AF11]
	connect -c n1/csl/pf0_0/AF11@$i -to $tm_/in@
	connect -c $tm_/bytecount@ -to $plot_/0@$j
	set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm$i\_AF12]
	connect -c n1/csl/pf0_0/AF12@$i -to $tm_/in@
	connect -c $tm_/bytecount@ -to $plot_/1@$j
	set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm$i\_AF13]
	connect -c n1/csl/pf0_0/AF13@$i -to $tm_/in@
	connect -c $tm_/bytecount@ -to $plot_/2@$j
	set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm$i\_all]
	connect -c n1/csl/pf0_0/all@$i -to $tm_/in@
	connect -c $tm_/bytecount@ -to $plot_/3@$j
}
! .tm?_* configure 2.0 0.5; # window size, update interval
set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm5\_EF]
$tm_ configure 20 10
connect -c n1/csl/pf0_0/EF@5 -to $tm_/in@
connect -c $tm_/bytecount@ -to $plot_/4@2
connect -c $tm_/bytecount@ -to $plot_/4@3
}
} else {
	mkdir h8/csl/$port@up
}

proc ConfigProfile {meterType markerType source trafficConditioner} {
	if [string match "Meter" $meterType] {
		set meter [java::null]
	} else {
		set meter [java::new drcl.diffserv.$meterType]
	}
	set profile [java::new drcl.diffserv.DFProfile]
	$profile set [java::new drcl.diffserv.Marker $markerType] $meter 
	! $trafficConditioner addProfile [! $source getDefaultAddress] $profile
	return $profile
}

if $toSetupHostTC {
puts "Setting up end hosts marker"
ConfigProfile "Meter" "SET_AF11" h3 h3/csl/pf0_0
ConfigProfile "Meter" "SET_AF11" h4 h4/csl/pf0_0
ConfigProfile "Meter" "SET_EF"   h5 h5/csl/pf0_0
}

if $toSetupEdgeTC {
puts "Setting up edge router"
# for host 3, we need rtt * target_rate (2.5e5) ~ 104560 bit burst to accommodate
# for host 4, we need rtt * target_rate (5.0e5) ~ 204560 bit burst to accommodate
set tg_rate 250000
set burst 104560; # bits
set p [ConfigProfile "TC_meter" "COLOR_AWARE" h3 n1/csl/pf0_0]
[!!! [$p getMeter]] config "SINGLE_RATE" $burst $tg_rate $burst 0; # last rate doesn't matter
[!!! [$p getMeter]] setDebugEnabled true

set tg_rate 500000
set burst 204560; # bits
set p [ConfigProfile "TC_meter" "COLOR_AWARE" h4 n1/csl/pf0_0]
[!!! [$p getMeter]] config "TWO_RATE" $burst $tg_rate [expr int($burst*1.2)] [expr int($tg_rate*1.2)]
[!!! [$p getMeter]] setDebugEnabled true

set tg_rate 136000
set burst 8000; # bits
set p [ConfigProfile "TB_meter" "POLICER" h5 n1/csl/pf0_0]
[!!! [$p getMeter]] config $burst $tg_rate;
}

if $toSetupCoreQ {
#set up HQS with EF, AF11 and BS FIFO queue served by pq
puts "Setting up HQS"
set bs_queue [java::new drcl.inet.core.queue.DropTail "bs_q"]
#set af1x_queue [java::new drcl.diffserv.scheduling.ColorQueue "af1x_q"]
set af1x_queue [java::new drcl.inet.core.queue.DropTail "af1x_q"]
set af2x_queue [java::new drcl.inet.core.queue.DropTail "af2x_q"]
set ef_queue [java::new drcl.inet.core.queue.DropTail "ef_q"]
$bs_queue setCapacity 8000; # bytes
$af1x_queue setCapacity 16000
$af2x_queue setCapacity 16000
$ef_queue setCapacity 8000

set AF1xWeight 1
set AF2xWeight 1
set dscpmask_ [java::field drcl.diffserv.DFConstants DSCPMask]
set dfclassmask_ [java::field drcl.diffserv.DFConstants DFCLASS_MASK]
set AF_queue [java::new drcl.diffserv.scheduling.wrr "af_wrr"]
$AF_queue setClassIDMask $dscpmask_
$AF_queue addQueueSet $af1x_queue $dfclassmask_ [java::field drcl.diffserv.DFConstants AF11_TOS] $AF1xWeight
$AF_queue addQueueSet $af2x_queue $dfclassmask_ [java::field drcl.diffserv.DFConstants AF21_TOS] $AF2xWeight

if 0 {
puts "Setup 3ColorQueue"
$af1x_queue setDefault
$af1x_queue config  3000 16000 10000000 \
					 100 16100 100 \
					 100 1600  5 \
					.02  $bandwidth 500
$af1x_queue reset
}

puts "Setup queue sets"
! n0/csl/q1 setClassIDMask $dscpmask_
! n0/csl/q1 addQueueSet $ef_queue $dscpmask_ [java::field  drcl.diffserv.DFConstants EF_TOS]
! n0/csl/q1 addQueueSet $AF_queue 0 0
! n0/csl/q1 addQueueSet $bs_queue $dscpmask_ [java::field drcl.diffserv.DFConstants BE_TOS]
}

# END CONFIGURE PROFILER & HQS

setflag garbagedisplay true recursively n0/csl/q1

puts "simulation begins..."	
set sim [attach_simulator event .]

$sim stop

if $toSetupCBR {
puts "start cbr source"
run h5
}

puts "start tcp sources"
#! h3-4/tcp setImplementation vegas
run h3,h4

script {puts [$sim getTime]} -period 10.0 -on $sim
$sim resumeTo 50
#script {puts [$sim diag]; quit} -at 50.0 -on $sim
#$sim resume

puts done!
