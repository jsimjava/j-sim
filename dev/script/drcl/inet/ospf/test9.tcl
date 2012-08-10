# test9.tcl
#
# Testing LS_REFRESH (every 1800 seconds)
#
# Topology:
# n0 ---- n1 ---- n2
#  |       |       |
#  |       |       |
# n3 ---- n4 ---- n5
#  |       |       |
#  |       |       |
# n6 ---- n7 ---- n8

source "../../../test/include.tcl"

cd [mkdir drcl.comp.Component /ospftest]

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]

# Nodes:
puts "\nCreate nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.01;  # 10 msecs
set adjMatrix_ [java::call drcl.inet.InetUtil createMeshAdjMatrix 3 3]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $adjMatrix_ $link_
puts "Node build..."
$nb build [! n*] "ospf drcl.inet.protocol.ospf.OSPF"

# observe neighbor events
watch -label NEIGHBOR -add n*/csl/.if@

if { $testflag } {
	attach -c $testfile/in@ -to n*/csl/.if@
}

# simulator
puts "Attach simulator..."
set sim [attach_simulator .]

#puts "Setting debug flags for OSPF ..."
#setflag debug true n*/ospf
setflag debug true -at sample n0/ospf
#setflag debug true n12/ospf
#setflag debug true n24/ospf


# set area id
! n*/ospf ospf_set_area_id 1

# start OSPF
#$sim setDebugEnabled true
#$sim setDebugEnabledAt "WF RECYCLE THREAD Q LEAP" true
#fm [!! . n*] setDebugEnabled true
$sim stop
run n*

## first disable interface 0 of node 0 temporarily
#script -at  100.0 -on $sim {puts "\nDisconnect link n0 -- n1 at 100.0 sim secs " }
#script -at  100.0 -on $sim {setflag component false n0/0@/-/..} 
#script -at  200.0 -on $sim {puts "\nRe-connect link n0 -- n1 at 200.0 sim secs "}
#script -at  200.0 -on $sim {setflag component true n0/0@/-/..}
#script -at 300.0 -on $sim {puts "\nSimulation time : 300.0 sec"}
#$sim stopAt 301.0
script -at 1800.0 -on $sim {setflag debug true n0/ospf}
$sim stopAt 1830.0
$sim resume

# The following method to disable OSPF is not workable in the current stage
# because OSPF rely on drcl.inet.core.Hello to exchange the hello message.
# We will solve this problem in the next stage.
#script -at  30.0 {setflag component false n2/ospf} -on $sim
#script -at 100.0 {setflag component true n2/ospf} -on $sim
#$sim stopAt 200.0
