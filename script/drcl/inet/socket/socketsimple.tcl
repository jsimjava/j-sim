# socketsimple.tcl
#
# Test drcl.inet.socket.InetSocket
# in a simple one connection 2-hop scenario
# Originally, Leonardo Querzoni [l.querzoni@virgilio.it] found a problem with
# TCP_socket with simple server/client code used in this script
#
# Topology:
# 
# h0 ----- n1 ----- h2

set MULTISESSION 1

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
if $MULTISESSION {
$nb build [! h0] {
	tcp 				drcl.inet.socket.TCP_full
	client    -/tcp		SimpleClient
}
$nb build [! h2] {
	tcp 				drcl.inet.socket.TCP_full
	server    -/tcp		SimpleServer
}
} else {
$nb build [! h0] {
	tcp 				drcl.inet.socket.TCP_socket
	client    -/tcp		SimpleClient
}
$nb build [! h2] {
	tcp 				drcl.inet.socket.TCP_socket
	server    -/tcp		SimpleServer
}
}

puts "setup static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h2] "bidirection"


# flags
setflag garbagedisplay true recursively .
#setflag trace true recursively .
#setflag trace true h?/tcp h0/client h2/server

puts "simulation runtime..."	
attach_simulator event .
#attach_simulator .

#setflag debug trace true h?/tcp

rt . stop
! h2/server setup 2 20001; # listen on port 20001
! h0/client setup 0 2 20001; # to connect to server on h2:20001
! h2/server setMultiSessionEnabled $MULTISESSION
! h0/client setMultiSessionEnabled $MULTISESSION

run h?
rt . resume

