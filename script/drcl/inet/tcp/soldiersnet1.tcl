# inet3_ex.tcl
#
# Topology:
# h0 ----\                  /------- h5
#         \               /
# h1 ----- n3 ----- n4 ----- h6
#         /   \     /   \ 
# h2 ----/     \   /      \-----h7
#               n8
#             /  |  \
#           /    |    \
#           h9  h10  h11

cd [mkdir -q drcl.comp.Component /example]

puts "create topology..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.3; # 300ms
set adjMatrix_ [java::new {int[][]} 12 {{3} {3} {3} {0 1 2 4 8} {3 5 6 7 8} {4} {4} {4} {3  4 9 10 11} {8} {8} {8}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "create builders..."
# router builder:
set rb [mkdir drcl.inet.NodeBuilder .routeBuilder]
$rb setBandwidth 1.0e6; #1Mbps

# source builder:
set hb1 [cp $rb .hostBuilder1]
#	#[mkdir drcl.inet.transport.TCP $hb1/tcp] setMSS 512; # bytes
#	set src_ [mkdir drcl.inet.application.BulkSource $hb1/source]
#	$src_ setDataUnit 512
#	connect -c $src_/down@ -and $hb1/tcp/up@

# sink builder:
set hb2 [cp $rb .hostBuilder2]
	#mkdir drcl.inet.transport.TCPSink $hb2/tcpsink
	#set sink_ [mkdir drcl.inet.application.BulkSink $hb2/sink]
	#connect -c $sink_/down@ -and $hb2/tcpsink/up@


puts "build..."
$rb build [! n?]

$rb build [! h0-2] {
	tcp 				drcl.inet.transport.TCP
	tcp2 	1006/csl	drcl.inet.transport.TCP
	tcp3 	1007/csl	drcl.inet.transport.TCP
	source 	-/tcp	 	drcl.inet.application.BulkSource
	source2   -/tcp2	drcl.inet.application.BulkSource
	source3   -/tcp3	drcl.inet.application.BulkSource
}


$rb build [! h5-7,h9-11] {
	tcpsink 			drcl.inet.transport.TCPSink
	tcpsink2 1006/csl	drcl.inet.transport.TCPSink
	tcpsink3 1007/csl	drcl.inet.transport.TCPSink
	sink 	-/tcpsink	drcl.inet.application.BulkSink
	sink2 	-/tcpsink2	drcl.inet.application.BulkSink
	sink3 	-/tcpsink3	drcl.inet.application.BulkSink
}
if 0 {
$rb build [! h9-11] {
	tcpsink 			drcl.inet.transport.TCPSink
	tcpsink2 1006/csl	drcl.inet.transport.TCPSink
	tcpsink3 1007/csl	drcl.inet.transport.TCPSink
	sink 	-/tcpsink	drcl.inet.application.BulkSink
	sink2 	-/tcpsink2	drcl.inet.application.BulkSink
	sink3 	-/tcpsink3	drcl.inet.application.BulkSink
}
}


puts "Configure TCP's, source and sink..."
! .../tcp* setMSS 512; # bytes
! h*/s* setDataUnit 512

# Configure the bottleneck bandwidth and buffer size
! n3 setBandwidth 3 1.0e5; # 100Kbps at interface 3
! n3 setBufferSize 3 6000; # ~10 packets at interface 3
! n3 setBandwidth 4 1.0e5; # 100Kbps at interface 4
! n3 setBufferSize 4 6000; # ~10 packets at interface 4

puts "set up static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h5] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h7] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h9] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h11] "bidirection"

java::call drcl.inet.InetUtil setupRoutes [! h1] [! h6] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h1] [! h10] "bidirection"

java::call drcl.inet.InetUtil setupRoutes [! h2] [! h7] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h2] [! h11] "bidirection"

puts "set up plotter..."
set plot_ [mkdir drcl.comp.tool.Plotter .plot]
#set file_ [mkdir drcl.comp.io.FileComponent .file]
#$file_ open "ex1.plot"
#connect -c $plot_/.output@ -to $file_/in@
#setflag plot false $plot_
attach -c $plot_/0@0 -to h0/tcp/cwnd@
attach -c $plot_/0@1 -to h0/tcp2/cwnd@
attach -c $plot_/1@1 -to h0/tcp3/cwnd@
attach -c $plot_/1@0 -to h1/tcp/cwnd@
attach -c $plot_/2@1 -to h1/tcp2/cwnd@

puts "set up nam trace..."
#set nam [java::call drcl.inet.InetUtil setNamTraceOn [! .] "ex1.nam" \
#	[_to_string_array "red blue orange green black yellow green"]]

set sim [attach_simulator event .]
$sim stop;       # stop the simulation first to complete the scenario
run h0-1/source*

puts "script"

! h0/tcp setPeer 5
! h0/tcp2 setPeer 9
! h0/tcp3 setPeer 11
! h1/tcp setPeer 6
! h1/tcp2 setPeer 10
! h1/tcp3 setPeer 100

#run h0/source
#run h0/source2
#run h0/source3

#script "run h0/source" -at 0.0  -on $sim ; 
#script "run h0/source2"  -at 20.0 -on $sim;
#script {puts [$sim getTime]} -at 0.0 -period 1.0 -on $sim; # to print simulation time
$sim resumeTo 200.0


