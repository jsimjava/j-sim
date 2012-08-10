# tcptest2_4.tcl
#
# same as tcptest2.tcl but use drcl.comp.tool.PlotPlain instead of Plotter
#
# Topology:
# h0 ---\               /--- h5
#        \             /
# h1 ----- n3 ----- n4 ----- h6
#        /             \
# h2 ---/               \--- h7

java::call drcl.util.MiscUtil markTime

set MSS 960; # to make it 1000 the whole IP packet
set NS_COMPATIBLE false

java::field drcl.inet.transport.TCP NS_COMPATIBLE $NS_COMPATIBLE
java::field drcl.inet.transport.TCPSink NS_COMPATIBLE $NS_COMPATIBLE

cd [mkdir -q drcl.comp.Component /test]

# create the topology
puts "create topology..."
#set link_ [java::new drcl.inet.Link]
#$link_ setPropDelay 0.05; # 50ms
set link_ [java::cast drcl.inet.Link [java::null]]
set adjMatrix_ [java::new {int[][]} 8 {{3} {3} {3} {0 1 2 4} {3 5 6 7} {4} {4} {4}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "create builders..."
# node builder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e6; #1Mbps
$nb setLinkEmulationEnabled true
$nb setLinkPropDelay .05;

puts "build..."
$nb build [! n?]
$nb build [! h0-2] {
	tcp 				drcl.inet.transport.TCP
	source	-/tcp		drcl.inet.application.BulkSource
}
$nb build [! h5-7] {
	tcpsink 			drcl.inet.transport.TCPSink
	sink	-/tcpsink	drcl.inet.application.BulkSink
}
! h?/tcp* setMSS $MSS; # bytes
! h?/s* setDataUnit $MSS

# Configure the bottleneck bandwidth and buffer size
! n3 setBandwidth 3 1.0e5; # 100Kbps at interface 3
! n4 setBandwidth 0 1.0e5; # 100Kbps at interface 0
! n3 setBuffer 3 9 packet; # 9+1 packets at interface 3

# Set up TCP connections
! h0/tcp setPeer 5
! h1/tcp setPeer 6
! h2/tcp setPeer 7

puts "setup static routes..."
if 1 {
	java::call drcl.inet.InetUtil setupRoutes [! h0] [! h5] "bidirection"
	java::call drcl.inet.InetUtil setupRoutes [! h1] [! h6] "bidirection"
	java::call drcl.inet.InetUtil setupRoutes [! h2] [! h7] "bidirection"
} else {
	! n3/csl/pd setLabelSwitches [java::new {int[][][]} 4 {{{3 0}} {{3 1}} {{3 2}} {{0 -1} {1 -1} {2 -1}}}]
	! n4/csl/pd setLabelSwitches [java::new {int[][][]} 4 {{{1 -1} {2 -1} {3 -1}} {{0 0}} {{0 1}} {{0 2}}}]
	setflag labelSwitching true n?/csl/pd
}

if 1 {
puts "Set up TrafficMonitor & Plotter..."
set plot_ [mkdir drcl.comp.tool.PlotPlain .plot]
$plot_ setFileSeparator "-"
$plot_ setFilePrefix "Result"
$plot_ setValueSeparator "\t"

if 1 {; # throughput/received seq#
foreach i {5 6 7} {
	set j [expr $i-5]
	if 1 {;# throughput
		set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm$i]
		$tm_ configure 10.0 4.0; # window size, update interval
		connect -c h$i/csl/6@up -to .tm$i/in@
		connect -c .tm$i/bytecount@ -to $plot_/$j@0
	}
	#connect -c h$i/tcpsink/seqno@ -to $plot_/$j@2
}
}
if 1 {
foreach i {0 1 2} {
	connect -c h$i/tcp/cwnd@ -to $plot_/$i@1
	connect -c h$i/tcp/srtt@ -to $plot_/$i@3
}
}
}

if 0 {
puts "Set up NamTrace..."

setflag garbage true .../q?

# Name of the file to which traces are written:
set outfile "tcptest2.nam"

# create NamTrace and FileComponent
set nam [mkdir -q drcl.inet.tool.NamTrace .nam]
set file2 [mkdir drcl.comp.io.FileComponent .file2]
connect -c $nam/output@ -to $file2/in@
$nam setMSS $MSS
$file2 open $outfile

# this sets up node, link and queue events, and create/connect event ports on $nam
java::call drcl.inet.InetUtil setNamTraceOn [! .] $nam
# configre colors for nam trace
$nam addColors [_to_string_array "red blue yellow green black orange"]; # six flows at most
}

puts "Scenario built."
puts "Time elapsed: [java::call drcl.util.MiscUtil timeElapsed] seconds"

puts "--------------------------\nsimulation begins..."	
set sim [attach_simulator event .]
$sim stop
#! h0-1/tcp setImplementation new-reno
#setflag sack true h0,h5/tcp*
#setflag garbagedisplay true .../q?
#setflag debug true h0/tcp
#run h0-1
run h?

java::new drcl.ruv.WaitUntil $sim 500
$plot_ flush
puts "Done!"
