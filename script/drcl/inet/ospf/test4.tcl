# test4.tcl
#
# Topology:
# n0 ---- n1
#  |       |
#  |       |
# n2 ---- n3 ---- n4



cd [mkdir drcl.comp.Component /ospftest]

# Nodes:
puts "\nCreate nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.01;  # 10 msecs
set adjMatrix_ [java::new {int[][]} 5 {{1 2} {0 3} {0 3} {1 2 4} {3}}]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $adjMatrix_ $link_

puts "Node build..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb build [! n*] "ospf drcl.inet.protocol.ospf.OSPF"

# observe neighbor events
watch -label NEIGHBOR -add n*/csl/.if@

# simulator
puts "Attach simulator..."
set sim [attach_simulator 3 .]

# set area id
! n*/ospf ospf_set_area_id 1

# start OSPF
$sim stop
run n*

## first disable interface 0 of node 0 temporarily
#script -at  50.0 -on $sim {puts "\nDisconnect link n0 -- n1 at 30.0 sim secs " }
#script -at  80.0 -on $sim {setflag component false n0/0@/-/..} 
#script -at  100.0 -on $sim {puts "\nRe-connect link n0 -- n1 at 100.0 sim secs "}
#script -at  100.0 -on $sim {setflag component true n0/0@/-/..} 
script -at 50.0 -on $sim {puts "\nSimulation time : 50.0 sec"}
$sim resumeTo 51.0

# The following method to disable OSPF is not workable in the current stage
# because OSPF rely on drcl.inet.core.Hello to exchange the hello message.
# We will solve this problem in the next stage.
#script -at  30.0 {setflag component false n2/ospf} -on $sim
#script -at 100.0 {setflag component true n2/ospf} -on $sim
#$sim stopAt 200.0
