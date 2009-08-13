# tcp.tcl
#
# Test drcl.inet.transport.TCP/TCPSink
# with a 3-connections 3-hop network
# using link emulation
#
# Topology:
# h0 ---\               /--- h5
#        \             /
# h1 ----- n3 ----- n4 ----- h6
#        /             \
# h2 ---/               \--- h7

source "../../../test/include.tcl"

set MSS 960; # to make it 1000 the whole IP packet

cd [mkdir -q drcl.comp.Component /test]

# create the topology
puts "create topology..."
set link_ [java::cast drcl.inet.Link [java::null]]
set adjMatrix_ [java::new {int[][]} 8 {{3} {3} {3} {0 1 2 4} {3 5 6 7} {4} {4} {4}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "create builders..."
# node builder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e6; #1Mbps
$nb setLinkEmulationEnabled true
$nb setLinkPropDelay .05

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
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h5] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h1] [! h6] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h2] [! h7] "bidirection"

if 1 {
puts "Set up TrafficMonitor & Plotter..."
set plot_ [mkdir drcl.comp.tool.Plotter .plot]
if 0 {; # save plot to file
	setflag plot false $plot_
	set file_ [mkdir drcl.comp.io.FileComponent .file]
	$file_ open tcptest2.plot
	connect -c $plot_/.output@ -to $file_/in@
}
if 1 {; # throughput/received seq#
foreach i {5 6 7} {
	set j [expr $i-5]
	if 1 {;# throughput
		set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm$i]
		$tm_ configure 10.0 4.0; # window size, update interval
		connect -c h$i/csl/6@up -to .tm$i/in@
		connect -c .tm$i/bytecount@ -to $plot_/$j@0

		if { $testflag } {
			attach -c $testfile/in@ -to .tm$i/bytecount@
		}

	}
	#connect -c h$i/tcpsink/seqno@ -to $plot_/$j@2
}
}
if 0 {
foreach i {0 1 2} {
	connect -c h$i/tcp/cwnd@ -to $plot_/$i@1
	connect -c h$i/tcp/srtt@ -to $plot_/$i@3
}
}
}

puts "simulation begins..."	
set sim [attach_simulator event .]
$sim stop
run h?

$sim resumeTo 500

