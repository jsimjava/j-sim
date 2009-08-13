# Topology:
# h0 ---\               /--- h5
#        \             /
# h1 ----- n3 ----- n4 ----- h6
#        /             \
# h2 ---/               \--- h7

source "../../../test/include.tcl"

cd [mkdir -q drcl.comp.Component /ex1]

# create the topology
puts "create topology..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.3; # 300ms
set adjMatrix_ [java::new {int[][]} 8 {{3} {3} {3} {0 1 2 4} {3 5 6 7} {4} {4} {4}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "create builders..."
# csl builder for router builder:
set cb [mkdir drcl.inet.core.CSLBuilder .cslBuilder]
set q_ [mkdir drcl.inet.core.queue.FIFO $cb/q3]; # only at interface 3

puts "build..."
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e7; #10Mbps
$nb build [! n3] $cb
$nb build [! n4]
$nb build [! h0-2] {
	tcp 					drcl.inet.transport.TCP
	source 		-/tcp 		drcl.inet.application.BulkSource
}
$nb build [! h5-7] {
	tcpsink 				drcl.inet.transport.TCPSink
	sink 		-/tcpsink 	drcl.inet.application.BulkSink
}
! h?/tcp* setMSS 512; # bytes
! h?/s* setDataUnit 512

# Configure the bottleneck bandwidth and buffer size
! n3 setBandwidth 3 1.0e4; # 10Kbps at interface 3
! n3 setBuffer 3 20 packet; # 20 packets at interface 3

# Set up TCP connections
! h0/tcp setPeer 5
! h1/tcp setPeer 6
! h2/tcp setPeer 7

puts "setup static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h5] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h1] [! h6] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h2] [! h7] "bidirection"

puts "Set up TrafficMonitor & Plotter..."
if 1 {
set plot_ [mkdir drcl.comp.tool.Plotter .plot]
foreach i {5 6 7} {
	set j [expr $i-5]
	set tm$j\_ [mkdir drcl.net.tool.TrafficMonitor .tm$j]
	connect -c h$i/csl/19@up -to .tm$j/in@
	connect -c .tm$j/bytecount@ -to $plot_/$j@0
	connect -c h$i/tcpsink/seqno@ -to $plot_/$j@2

	if { $testflag } {
		attach -c $testfile/in@ -to .tm$j/bytecount@
		attach -c $testfile/in@ -to h$i/tcpsink/seqno@ 
	}
}
! .tm? configure 10.0 4.0; # window size, update interval
foreach i {0 1 2} {
	connect -c h$i/tcp/cwnd@ -to $plot_/$i@1
	connect -c h$i/tcp/rtt@ -to $plot_/$i@3

	if { $testflag } {
		attach -c $testfile/in@ -to h$i/tcp/cwnd@
		attach -c $testfile/in@ -to h$i/tcp/rtt@
	}
}
connect -c n3/csl/q3/.avgq@ -to $plot_/0@4
connect -c n3/csl/q3/.q@ -to $plot_/1@4
set linktm_ [mkdir drcl.net.tool.TrafficMonitor .linktm]
attach -c $linktm_/in@ -to n3/csl/ni3/down@
connect -c $linktm_/bytecount@ -to $plot_/3@0

	if { $testflag } {
		attach -c $testfile/in@ -to $linktm_/bytecount@
	}
}

#setflag garbagedisplay true recursively .
puts "simulation begins..."	
set sim [attach_simulator .]
$sim stop
run .../sink h0/source
script {puts "start h1"; run h1/source} -at 50.0 -on $sim
script {puts "start h2"; run h2/source} -at 100.0 -on $sim
script {puts "stop h0"; stop h0/source} -at 600.0 -on $sim
script {puts "stop h1"; stop h1/source} -at 1000.0 -on $sim
script {puts [$sim getTime]} -period 50.0 -at 50.0 -on $sim

$sim resumeTo 1200
