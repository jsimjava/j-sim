# test_fsp.tcl
#
# Testing drcl.inet.application.fsp/fspd
#
# Topology:
# n0 --------- n1--h4
# |\           |
# | \--------\ |
# |           \|
# n2 --------- n3
# |
# \--h5
#
# Start a file transfer by:
# ! h4/fsp get <remove_file_name> <local_file_name> <block_size> <peer_addr> <peer_port>

set SOURCE_FILE "foo.jpg"
set LOCAL_FILE "result.jpg"

# test root
cd [mkdir -q drcl.comp.Component /test]

# Nodes:
puts "create routers and hosts..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set adjMatrix_ [java::new {int[][]} 6 {{1 2 3} {3 0 4} {0 3 5} {0 1 2} {1} {2}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "build..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e6; #1Mbps
set fspd_port 1501
$nb build [! n?]
$nb build [! h4] {
	udp					drcl.inet.transport.UDP
	fsp		1001/udp	drcl.inet.application.fsp
}
$nb build [! h5] {
	udp					drcl.inet.transport.UDP
	fspd	1501/udp	drcl.inet.application.fspd
}

# setup routing tables
puts "set up routes..."
java::call drcl.inet.InetUtil setupRoutes [! h4] [! h5] "bidirection"

# simulator
puts "simulator..."
set sim [attach_simulator .]

# start the server
run h5/fspd

# turn on fsp's debug flag: fsp will notify end of transfer with debug msg
setflag debug true h4/fsp

# fsp get source_file_at_remote local_file block_size(byte) remote_node remote_port
set cmd {! h4/fsp get $SOURCE_FILE $LOCAL_FILE 1024 5 $fspd_port}
mkdir drcl.comp.tool.DataCounter h4/counter
connect -c h4/fsp/down@ -to h4/counter/in@

eval $cmd
