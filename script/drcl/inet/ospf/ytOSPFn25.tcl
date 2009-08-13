# ytOSPFn25.tcl
#
# Modified by Youngtak Kim to test scalability, multithreads and routing
# dynamics (wire failure/recovery)
#
# Topology : 5 x 5 mesh
# Topology:
# n0 ---- n1 ---- n2 ---- n3 ---- n4
#  |       |       |       |       |
#  |       |       |       |       |
# n5 ---- n6 ---- n7 ---- n8 ---- n9
#  |       |       |       |       |
#  |       |       |       |       |
# n10---- n11---- n12---- n13---- n14
#  |       |       |       |       |
#  |       |       |       |       |
# n15---- n16---- n17---- n18---- n19
#  |       |       |       |       |
#  |       |       |       |       |
# n20---- n21---- n22---- n23---- n24


################# result: #########################
# ===> should be modified !!
#	n0	n1	n2	n3	n4	n5
# n0     * 	0,1	1,1	2,1    0,2(2,2)	2,2
# n1	0,1	 *	0,2     1,1     2,1   1,2(2,2)	
# n2	0,1	0,2	 *	0,2	0,3	0,3
# n3	0,1     1,1     0,2	 *	2,1	3,1
# n4  0,2(1,2)	0,1   0,3(1,3)	1,1	 *	2,1
# n5	0,2   0,2(1,2)  0,3	0,1	1,1	 *

## if n0/0@ disconnected
# ====> should be modified !!
#	n0	n1	n2	n3	n4	n5
# n0     * 	2,2	1,1	2,1     2,2	2,2
# n1	1,2	 *	1,3     1,1     2,1   1,2(2,2)	
# n2	0,1	0,3	 *	0,2	0,3	0,3
# n3	0,1     1,1     0,2	 *	2,1	3,1
# n4    1,2	0,1     1,3	1,1	 *	2,1
# n5	0,2   0,2(1,2)  0,3	0,1	1,1	 *

cd [mkdir drcl.comp.Component /ospftest]

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]

# Nodes:
puts "\nCreate nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.01;  # 10 msecs
set adjMatrix_ [java::call drcl.inet.InetUtil createMeshAdjMatrix 5 5]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $adjMatrix_ $link_
puts "Node build..."
$nb build [! n*] "ospf drcl.inet.protocol.ospf.OSPF"

# observe neighbor events
watch -label NEIGHBOR -add n*/csl/.if@

# simulator
puts "Attach simulator..."
#set sim [attach_simulator 20 .]
set sim [attach_simulator event .]

puts "Setting debug flags for OSPF ..."
#setflag debug true n*/ospf
setflag debug true -at sample n0/ospf


# set area id
! n*/ospf ospf_set_area_id 1

# start OSPF
$sim stop
run n*

## first disable interface 0 of node 0 temporarily
script -at  30.0 -on $sim {cat n0}
script -at  30.0 -on $sim {puts "\nDisconnect link n0 -- n1 at 30.0 sim secs " }
script -at  30.0 -on $sim {setflag component false n0/0@/-/..} 
script -at  100.0 -on $sim {cat n0}
script -at  100.0 -on $sim {puts "\nRe-connect link n0 -- n1 at 100.0 sim secs "}
script -at  100.0 -on $sim {setflag component true n0/0@/-/..} 
script -at  200.0 -on $sim {cat n0}
script -at 200.0 -on $sim {puts "\nSimulation time : 200.0 sec"}
$sim stopAt 210.0
$sim resume

# The following method to disable OSPF is not workable in the current stage
# because OSPF rely on drcl.inet.core.Hello to exchange the hello message.
# We will solve this problem in the next stage.
#script -at  30.0 {setflag component false n2/ospf} -on $sim
#script -at 100.0 {setflag component true n2/ospf} -on $sim
#$sim stopAt 200.0
