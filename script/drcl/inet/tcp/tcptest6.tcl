# tcptest6.tcl
#
# Test static routing with network partitioning
#
# Topology:
# net0:        \ / net1:
# h0 ---\       |       /--- h0
#        \      |      /
# h1 ----- n3 --+-- n3 ----- h1
#        /      |      \
# h2 ---/      / \      \--- h2

set MSS 960; # to make it 1000 the whole IP packet

cd [mkdir -q drcl.comp.Component /test]
mkdir -q drcl.comp.Component net0

# create the topology
puts "create topology..."
#set link_ [java::new drcl.inet.Link]
#$link_ setPropDelay 0.05; # 50ms
set link_ [java::cast drcl.inet.Link [java::null]]
set adjMatrix_ [java::new {int[][]} 4 {{3} {3} {3} {0 1 2}}]
java::call drcl.inet.InetUtil createTopology [! net0] $adjMatrix_ $link_
connect -c net0/0@ -and net0/n3/3@

cp net0 net1
connect -c net0/0@ -and net1/0@

! net1/h0 addAddress 1000
! net1/h1 addAddress 1001
! net1/h2 addAddress 1002
! net1/n3 addAddress 1003

puts "create builders..."
# node builder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e6; #1Mbps

puts "build..."
$nb build [! net0-1/n3]
$nb build [! net0/h0-2] {
	tcp 				drcl.inet.transport.TCP
	source	-/tcp		drcl.inet.application.BulkSource
}
$nb build [! net1/h0-2] {
	tcpsink 			drcl.inet.transport.TCPSink
	sink	-/tcpsink	drcl.inet.application.BulkSink
}
! net0-1/h?/tcp* setMSS $MSS; # bytes
! net0-1/h?/s* setDataUnit $MSS
! net0-1/h?,n?/csl/ni? setPropDelay .05;

# Configure the bottleneck bandwidth and buffer size
! net0-1/n3 setBandwidth 3 1.0e5; # 100Kbps at interface 3
! net0/n3 setBuffer 3 9 packet; # 9+1 packets at interface 3

# Set up TCP connections
! net0/h0/tcp setPeer 1000 
! net0/h1/tcp setPeer 1001
! net0/h2/tcp setPeer 1002

puts "setup static routes..."
set r [mkdir drcl.inet.tool.routing_msp .routing]
$r setup [! net0/h0] [! net1/h0] "bidirection"
$r setup [! net0/h1] [! net1/h1] "bidirection"
$r setup [! net0/h2] [! net1/h2] "bidirection"

if 1 {
puts "Set up TrafficMonitor & Plotter..."
set plot_ [mkdir drcl.comp.tool.Plotter .plot]
if 0 {; # save plot to file
	setflag plot false $plot_
	set file_ [mkdir drcl.comp.io.FileComponent .file]
	$file_ open tcptest2.plot
	connect -c $plot_/.output@ -to $file_/in@
}
foreach i {0 1 2} {
	if 1 {;# throughput
		set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm$i]
		$tm_ configure 10.0 4.0; # window size, update interval
		connect -c net1/h$i/csl/6@up -to .tm$i/in@
		connect -c .tm$i/bytecount@ -to $plot_/$i@0
	}
	connect -c net1/h$i/tcpsink/seqno@ -to $plot_/$i@2

	connect -c net0/h$i/tcp/cwnd@ -to $plot_/$i@1
	connect -c net0/h$i/tcp/srtt@ -to $plot_/$i@3
}
}

puts "--------------------------\nsimulation begins..."	
attach_simulator event .
run net0-1/h?
rt . stopAt 500

