# tcp1.tcl
#
# Run two copies of a network with
# one running TCP Tahoe and the other TCP Reno
#
# Topology:
# 
# h0 ----- n1 ----- h2

java::field drcl.inet.transport.TCP INIT_SS_THRESHOLD 16

cd [mkdir drcl.comp.Component /test]

puts "create builders..."

# create the node
puts "create nodes..."
cd [mkdir drcl.comp.Component net0]
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.3; # 300 ms
set adjMatrix_ [java::new {int[][]} 3 {{1} {0 2} {1}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "build..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e7; #10Mbps
$nb build [! n?]
$nb build [! h0] {
	tcp 				drcl.inet.transport.TCP
	source 	-/tcp		drcl.inet.application.BulkSource
}
$nb build [! h2] {
	tcpsink 			drcl.inet.transport.TCPSink
	sink 	-/tcpsink	drcl.inet.application.BulkSink
}
! h?/tcp* setMSS 512
! h?/s* setDataUnit 512
! n1 setBandwidth 1 1.0e4; # 10Kbps at interface 1
#! n1 setBufferSize 1 6000; # ~10 packets at interface 1
! n1 setBuffer 1 10 packet; # ~10 packets at interface 1
    	    
puts "setup tcp's/applications..."
! h0/tcp setPeer 2

puts "setup static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h2] "bidirection"

cd ..
cp net0 net1
! net1/h0/tcp setImplementation Tahoe
! net1/h0/tcp setPeer 2
	
puts "set up simulator..."
attach_simulator .

puts "TrafficMonitor and Plotter..."
mkdir drcl.comp.Component .monitor
set plot_ [mkdir drcl.comp.tool.Plotter .monitor/plot]
setflag output false $plot_; # set true to output to the file below
setflag plot true $plot_

set file_ [mkdir drcl.comp.io.FileComponent .file]
#$file_ open "tmp"
connect -c $plot_/.output@ -to $file_/in@

foreach i "0 1" {
connect -c net$i/h0/tcp/cwnd@ -to $plot_/$i@0
connect -c net$i/h0/tcp/sst@ -to $plot_/[expr $i+2]@0
connect -c net$i/h2/tcpsink/seqno@ -to $plot_/$i@1
connect -c net$i/h0/tcp/rtt@ -to $plot_/$i@2
}

# flags
setflag GarbageDisplay true recursively net?/*
#setflag debug true -at "dupack" .../tcp
puts "simulation begins..."	
run net?
script -at 100 -on [rt -q .] {puts [rt .]}
rt . stopAt 100
