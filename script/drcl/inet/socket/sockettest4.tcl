# sockettest4.tcl
#
# Test drcl.inet.socket.InetSocket and TCP_full:
# simultaneous TCP sessions, socket.listen()
#
# Topology:
# 
# h0 ----- n1 ----- h2

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
$nb build [! h0] {
	tcp 				drcl.inet.socket.TCP_full
	client    -/tcp		HelloClient4
}
$nb build [! h2] {
	tcp 				drcl.inet.socket.TCP_full
	server    -/tcp		HelloServer3
}

puts "setup static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h2] "bidirection"


# flags
setflag garbagedisplay true recursively .
#setflag trace true recursively .
#setflag trace true h?/tcp h0/client h2/server
#setflag trace true h0/client h2/server
#setflag debug true h2/tcp

puts "simulation runtime..."	
#set sim [attach_simulator event .]
set sim [attach_simulator 20 .]
#attach_runtime .
$sim stop

#setflag debug trace true h?/tcp

! h2/server setup 2 20001; # listen on port 20001
! h0/client setup 0 2 20001; # to connect to server on h2:20001
! h2/server setMultiSessionEnabled 1
! h0/client setMultiSessionEnabled 1
run h?
run h0/client
run h0/client
$sim resume
