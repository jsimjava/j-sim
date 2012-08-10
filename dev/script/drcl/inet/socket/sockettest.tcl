# sockettest.tcl
#
# Test real applications HelloServer, HelloClient with the drcl.inet.socket
# package.
#
# Topology:
# 
#   HelloClient                    HelloServer
# (www.cs.uiuc.edu)              (www.yahoo.com)
#        h0 ----------- n1 ----------- h2

cd [mkdir -q drcl.comp.Component /test]

# create the topology
puts "create topology..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.03; # 300ms
set adjMatrix_ [java::new {int[][]} 3 {{1} {0 2} {1}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "create builders..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e7; #10Mbps

puts "build..."
$nb build [! n?]
$nb build [! h?] {
	tcp 				drcl.inet.socket.TCP_full
}

puts "setup static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h2] "bidirection"

if 0 {
puts "Set up TrafficMonitor & Plotter..."
set plot_ [mkdir drcl.comp.tool.Plotter .plot]
if 0 {
	setflag plot false $plot_
	set file [mkdir drcl.comp.io.FileComponent .file]
	$file open "test.plot"
	connect -c $plot_/.output@ -to $file/in@
} else {
	#[$plot_ getPlot 1] setStepwise true
	#set p [$plot_ getPlot 2]
	#foreach i {0 1 2} { $p setConnected false $i }
	#foreach i {0 2} { $p setMarksStyle dots $i }
	#$p setMarksStyle points 1
}
set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm]
connect -c h2/csl/6@up -to $tm_/in@
connect -c $tm_/bytecount@ -to $plot_/0@0
connect -c h0/tcp/cwnd@ -to $plot_/0@1
connect -c h0/tcp/rtt@ -to $plot_/0@3
connect -c h0/tcp/seqno@ -to $plot_/0@2
connect -c h0/tcp/ack@ -to $plot_/1@2
connect -c h2/tcpsink/seqno@ -to $plot_/2@2
}

# flags
setflag garbagedisplay true recursively .
#setflag trace true recursively .
#setflag trace true h?/tcp/down@

#puts "simulation runtime..."	
#attach_simulator .
attach_runtime .

puts "configuring launcher..."
set l [mkdir drcl.inet.socket.Launcher launcher]
$l configure {
		www.yahoo.com		2   #server
		www.cs.uiuc.edu		0   #client
}
$l takeover
set cmd1 {$l start HelloServer [java::new String\[\] 1 20001] [! h2]}
set cmd2 {$l start HelloClient [java::new String\[\] 2 {www.yahoo.com 20001}] [! h0]}
set cmd3 {$l start HelloServer [java::new String\[\] 1 20002] [! h2]}

proc _connect {} {
	setflag component true h0/0@/-/..
}

proc _disconnect {} {
	setflag component false h0/0@/-/..
}

puts "start server at h2"
eval $cmd1
puts "start client at h0"
eval $cmd2
