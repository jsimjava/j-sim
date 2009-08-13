# tcp_high.tcl
#
# TCP on high speed link
#
# Topology:
# 
# h0 ----- h1

java::field drcl.inet.transport.TCP AWND_DEFAULT 10000
java::field drcl.inet.transport.TCP MAXCWND_DEFAULT 10000
java::field drcl.inet.transport.TCP INIT_SS_THRESHOLD 10000

cd [mkdir drcl.comp.Component /test]

puts "create builders..."

# create the node
puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.025; # 25 ms
set adjMatrix_ [java::new {int[][]} 2 {{1} {0}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "build..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 10.0e9; #10Gbps
$nb build [! h0] {
	tcp 				drcl.inet.transport.TCP
	source 	-/tcp		drcl.inet.application.FileSource
}
$nb build [! h1] {
	tcpsink 			drcl.inet.transport.TCPSink
	sink 	-/tcpsink	drcl.inet.application.BulkSink
}
! h?/tcp* setMSS 575
! h?/s* setDataUnit 575
! h0/source setSize 5000000000
#! h0 setBuffer 0 10 packet; # ~10 packets at interface 1
     	    
puts "setup tcp's/applications..."
! h0/tcp setPeer 1

puts "set up simulator..."
attach_simulator event .

puts "TrafficMonitor and Plotter..."
mkdir drcl.comp.Component .monitor
set plot_ [mkdir drcl.comp.tool.Plotter .monitor/plot]
setflag output false $plot_; # set true to output to the file below
setflag plot true $plot_

set file_ [mkdir drcl.comp.io.FileComponent .file]
#$file_ open "tmp"
connect -c $plot_/.output@ -to $file_/in@

connect -c h0/tcp/cwnd@ -to $plot_/0@0
connect -c h0/tcp/sst@ -to $plot_/2@0
connect -c h1/tcpsink/seqno@ -to $plot_/0@1
connect -c h0/tcp/rtt@ -to $plot_/0@2

# flags
setflag GarbageDisplay true recursively h*/csl/ni0
#setflag debug true -at "dupack" .../tcp
puts "simulation begins..."	
#setflag trace true recursively h0
#setflag debug true h?/tcp*
run h?
