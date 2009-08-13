# multipath.tcl
#
# set up multiple paths from h4 to h5
#
# Topology:
#     n0 --------- n1--h5
#     |\           |
#     | \--------\ |
#     |           \|
# h4--n2 --------- n3
#

# test root
cd [mkdir -q drcl.comp.Component /example4]

puts "create topology..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.1; # 100ms
set adjMatrix_ [java::new {int[][]} 8 {{2 3} {3 5} {0 3 4} {0 1 2} {2} {1}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "build..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .routerBuilder]
$nb setBandwidth 1.0e6; # 1Mbps

$nb build [! n?]
$nb build [! h4] {
    tcp			drcl.inet.transport.TCP
    source   -/tcp	drcl.inet.application.BulkSource
}
$nb build [! h5] {
    tcpsink		drcl.inet.transport.TCPSink
    sink     -/tcpsink	drcl.inet.application.BulkSink
}

! n2 setBandwidth 1 10.0e3; # 10Kbps at interface 1
! n2 setBufferSize 1 6000; # ~10 TCP packets at interface 1

puts "set up tcp source/sink..."
! h4/tcp setPeer 5
! h4-5/tcp* setMSS 512
! h4-5/s* setDataUnit 512

# setup routing tables
puts "set up routes..."
java::call drcl.inet.InetUtil setupRoutes [! h4] [! h5] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! n0] [! h5]
if 1 {
set ifs [java::new drcl.data.BitSet [java::new {int[]} 2 {0 1}]]
set entry [java::new drcl.inet.data.RTEntry $ifs "multipath"]
set key [java::new drcl.inet.data.RTKey 0 0 5 -1 0 0]
! n2 addRTEntry $key $entry -1.0; # no timeout
}

puts "Set up TrafficMonitor & Plotter..."
set plot_ [mkdir drcl.comp.tool.Plotter .plot]
set tm_ [mkdir drcl.net.tool.TrafficMonitor .tm0]
connect -c h5/csl/6@up -to $tm_/in@
connect -c $tm_/bytecount@ -to $plot_/0@0
connect -c h4/tcp/cwnd@ -to $plot_/0@1
connect -c h5/tcpsink/seqno@ -to $plot_/0@2

# simulator
set sim [attach_simulator event .]
$sim stop
run h?
$sim resumeTo 100

