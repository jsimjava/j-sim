# test_protocol.OSPF.tcl
#
# Testing routing dynamics by cutting a wire and reconnect it again
#
# Topology:
# n0 --------- n1 ----------- n4
# |\           	|             /|
# | \--------\  |  /  -------/ |
# |           \ | /            |
# n2           n3 ----------- n5

cd [mkdir drcl.comp.Component /test]

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e6; # 1Mbps

# Nodes:
puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.001; # 1ms
set adjMatrix_ [java::new {int[][]} 6 {{1 2 3} {0 3 4} {0} {0 1 4 5} {1 3 5} { 3 4 }}]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $adjMatrix_ $link_
puts "build..."
$nb build [! n?] "ospf drcl.inet.protocol.ospf.OSPF"
! .../ospf ospf_set_area_id 1

# observe neighbor events
watch -label NEIGHBOR -add n?/csl/.if@

# simulator
puts "simulator..."
set sim [attach_simulator .]

setflag debug true -at sample n0/ospf

# start OSPF
$sim stop
! n? run

## first disable interface 0 of node 0 temporarily
script -at  30.0 -on $sim {cat n?}
script -at  30.0 -on $sim {puts "Disconnect n0 -- n3" }
script -at  30.0 -on $sim {setflag component false n0/2@/-/..} 
script -at  100.0 -on $sim {cat n?}
script -at  100.0 -on $sim {puts "Connect n0 -- n3"}
script -at  100.0 -on $sim {setflag component true n0/2@/-/..}
script -at  200.0 -on $sim {cat n?}
$sim stopAt 200.0
$sim resume
# The following method to disable OSPF is not workable in the current stage
# because OSPF rely on drcl.inet.core.Hello to exchange the hello message.
# We will solve this problem in the next stage.
#script -at  30.0 {setflag component false n2/ospf} -on $sim
#script -at 100.0 {setflag component true n2/ospf} -on $sim
#$sim stopAt 200.0
