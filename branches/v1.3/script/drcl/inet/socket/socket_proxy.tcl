# socket_proxy.tcl
#
# test BulkSourceClient, BulkSinkServer and ProxyServer
#
# Topology:
# 
# h0 (client0) --------------\ 
# h1 (client1) ----- n3 ----- n4 ----- h5 (proxy)
# h2 (server) ------/

cd [mkdir -q drcl.comp.Component /test]

# create the topology
puts "create topology..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.1; # 300ms
set adjMatrix_ [java::new {int[][]} 6 {4 3 3 {1 2 4} {0 3 5} 4}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "create builders..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e7; #10Mbps

puts "build..."
$nb build [! n?]
$nb build [! h0-1] {
	tcp 				drcl.inet.socket.TCP_full
	source 	-/tcp	 	BulkSourceClient
}
$nb build [! h2] {
	tcp		 			drcl.inet.socket.TCP_full
	sink 	-/tcp		BulkSinkServer
}
$nb build [! h5] {
	tcp		 			drcl.inet.socket.TCP_full
	proxy 	-/tcp		ProxyServer
}

# Configure the bottleneck bandwidth and buffer size
#! n1 setBandwidth 1 1.0e4; # 10Kbps at interface 1
#! n1 setBufferSize 1 6000; # ~10 packets at interface 1

puts "Configure TCP's, source and sink..."
! h?/s*,proxy setMultiSessionEnabled 1
! h?/s*,proxy setDataUnit 512
! h0/source bind 0 5 20001; # local, proxy, port
! h1/source bind 1 5 20001; # local, proxy, port
! h2/sink bind 2 20001; # local, port
! h5/proxy bind 5 2 20001; # local, server, port

puts "setup static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h5] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h1] [! h5] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h2] [! h5] "bidirection"

if 1 {
puts "Set up TrafficMonitor & Plotter..."
set plot_ [mkdir drcl.comp.tool.Plotter .plot]
set tm0_ [mkdir drcl.net.tool.TrafficMonitor .tm0]
set tm1_ [mkdir drcl.net.tool.TrafficMonitor .tm1]
set tm2_ [mkdir drcl.net.tool.TrafficMonitor .tm2]
connect -c h0/tcp/down@ -to $tm0_/in@
connect -c h1/tcp/down@ -to $tm1_/in@
connect -c h2/csl/6@up -to $tm2_/in@
connect -c $tm0_/bytecount@ -to $plot_/0@0
connect -c $tm1_/bytecount@ -to $plot_/1@0
connect -c $tm2_/bytecount@ -to $plot_/2@0
}

# flags
setflag garbagedisplay true .../ni*

puts "simulation begins..."	
set sim [attach_simulator event .]
$sim stop
run h?
script -at 1.0 -on $sim {
	connect -c h0/tcp/tcp10/cwnd@ -to $plot_/0@1
	connect -c h1/tcp/tcp10/cwnd@ -to $plot_/1@1
}
$sim resumeTo 100
