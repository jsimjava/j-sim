# test_tool.routing_msp.tcl
#
# Testing drcl.inet.tool.routing_msp
#
# Topology:
# n0 --------- n1
# |\           |
# | \--------\ |
# |           \|
# n2 --------- n3
#
# Try: 
# 1. eval $ucast_cmd
#    The packet will arrive at n1/csl/2@up
# 2. eval $mcast_cmd
#    The packet will arrive at n0,n1/csl/2@up

# test root
cd [mkdir -q drcl.comp.Component /test]

# Nodes:
puts "create routers and hosts..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set adjMatrix_ [java::new {int[][]} 4 {{1 2 3} {3 0} {0 3} {0 1 2}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "build..."
# NodeBuilder:
[mkdir drcl.inet.NodeBuilder .nodeBuilder] build [! n?]

puts "create input ports..."
mkdir n?/csl/2@up

puts "add identities & create RT entries"
! n0-1 addAddress -11
set msp [java::new drcl.inet.tool.routing_msp msp]
$msp setup [! n2] [! n1]
$msp setup [! n2] [! n0-1] -11

# watch for incoming data packets
watch -label n0 -add n0/csl/2@up
watch -label n1 -add n1/csl/2@up

# set up simulator
puts "simulator..."
set sim [attach_simulator .]

# create data for testing 
# arguments: data data_size source destination router_alert TTL ToS
set ucast_data [java::call drcl.inet.contract.PktSending getForwardPack "Hello!" 100 [java::field drcl.net.Address NULL_ADDR] 1 false 10 333]
set mcast_data [java::call drcl.inet.contract.PktSending getForwardPack "Hello!" 100 [java::field drcl.net.Address NULL_ADDR] -11 false 255 737]

set ucast_cmd {inject $ucast_data n2/csl/2@up}
set mcast_cmd {inject $mcast_data n2/csl/2@up}
setflag trace true n?

puts "Done!"
puts {Try with 'eval $ucast_cmd' for unicast or 'eval $mcast_cmd' for multicast}
