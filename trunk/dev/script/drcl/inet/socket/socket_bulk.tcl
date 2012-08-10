# socket_bulk.tcl
#
# test BulkSourceClient and BulkSinkServer
#
# Topology:
# 
# h0 ----- n1 ----- h2

set MULTISESSION 1

cd [mkdir -q drcl.comp.Component /test]

# create the topology
puts "create topology..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.1; # 300ms
set adjMatrix_ [java::new {int[][]} 3 {{1} {0 2} {1}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "create builders..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e7; #10Mbps

puts "build..."
$nb build [! n?]
if $MULTISESSION {
$nb build [! h0] {
	tcp 				drcl.inet.socket.TCP_full
	source 	-/tcp	 	BulkSourceClient
}
$nb build [! h2] {
	tcp		 			drcl.inet.socket.TCP_full
	sink 	-/tcp		BulkSinkServer
}
} else {
$nb build [! h0] {
	tcp 				drcl.inet.socket.TCP_socket
	source 	-/tcp	 	BulkSourceClient
}
$nb build [! h2] {
	tcp		 			drcl.inet.socket.TCP_socket
	sink 	-/tcp		BulkSinkServer
}
}

# Configure the bottleneck bandwidth and buffer size
! n1 setBandwidth 1 1.0e4; # 10Kbps at interface 1
! n1 setBufferSize 1 6000; # ~10 packets at interface 1

puts "Configure TCP's, source and sink..."
! h?/s* setMultiSessionEnabled $MULTISESSION
! h?/s* setDataUnit 512
! h0/source bind 0 2 20001
! h2/sink bind 2 20001

puts "setup static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h2] "bidirection"

if 1 {
puts "Set up TrafficMonitor & Plotter..."
set plot_ [mkdir drcl.comp.tool.Plotter .plot]
set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm]
connect -c h2/csl/6@up -to $tm_/in@
connect -c $tm_/bytecount@ -to $plot_/0@0
connect -c n1/csl/ni1/.avgq@ -to $plot_/0@3
connect -c n1/csl/ni1/.q@ -to $plot_/1@3
}

# flags
setflag garbagedisplay true .../ni*

puts "simulation begins..."	
set sim [attach_simulator event .]

run h?
rt . stopAt 100.0
