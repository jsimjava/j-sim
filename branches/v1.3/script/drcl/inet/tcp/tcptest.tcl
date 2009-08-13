# tcptest.tcl
#
# Test drcl.inet.transport.TCP/TCPSink
# in a simple one connection 2-hop scenario
#
# Topology:
# 
# h0 ----- n1 ----- h2

set event_ 1
if {$argc > 0} {
	if [string match [lindex $argv 0] "event"] {set event_ 1}
}

java::field drcl.comp.Port EXECUTION_BOUNDARY false

cd [mkdir -q drcl.comp.Component /test]

# create the topology
puts "create topology..."
set link_ [java::cast drcl.inet.Link [java::null]]
#set link_ [java::new drcl.inet.Link]
#$link_ setPropDelay 0.3; # 300ms
set adjMatrix_ [java::new {int[][]} 3 {{1} {0 2} {1}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "create builders..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setLinkEmulationEnabled true
$nb setLinkPropDelay .3
$nb setBandwidth 1.0e7; #10Mbps

puts "build..."
$nb build [! n?]
$nb build [! h0] {
	tcp 				drcl.inet.transport.TCP
	source 	-/tcp	 	drcl.inet.application.BulkSource
}
$nb build [! h2] {
	tcpsink 			drcl.inet.transport.TCPSink
	sink 	-/tcpsink	drcl.inet.application.BulkSink
}

# Configure the bottleneck bandwidth and buffer size
! n1 setBandwidth 1 1.0e4; # 10Kbps at interface 1
! n1 setBufferSize 1 6000; # ~10 packets at interface 1

puts "Configure TCP's, source and sink..."
! .../tcp* setMSS 512; # bytes
! h0/tcp setPeer 2
! h0,h2/s* setDataUnit 512

puts "setup static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h2] "bidirection"
#! n1/csl/pd setSwitches [java::new {int[]} 2 {1 0}]
#setflag switching true n1/csl/pd

if 1 {
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
connect -c h0/tcp/srtt@ -to $plot_/0@4
connect -c h0/tcp/seqno@ -to $plot_/0@2
connect -c h0/tcp/ack@ -to $plot_/1@2
connect -c h2/tcpsink/seqno@ -to $plot_/2@2
connect -c n1/csl/ni1/.avgq@ -to $plot_/0@3
connect -c n1/csl/ni1/.q@ -to $plot_/1@3
}

# flags
setflag garbagedisplay true .../ni*

puts "simulation begins..."	
if $event_ {
	attach_simulator event .
} else {
	attach_simulator .
}

#! h0/tcp setImplementation tahoe
#! h0/tcp setImplementation VEGAS
#! h0/tcp setImplementation new-reno
#setflag sack true h?/tcp*
#setflag trace true recursively h?/tcp*
#setflag debug true -at sample h?/tcp*
#setflag trace true h0/tcp/up@
run h?
rt . stopAt 100.0
#script {puts [rt . diag]; quit} -at 1000.0 -on [rt -q .]
