# ytOSPFn50.tcl
#
# Modified by Youngtak Kim to test scalability and routing dynamics (wire
# failure/recovery) with OSPF routing protocol
# Topology : 5 x 10 mesh
# Topology:
# n0 ---- n1 ---- n2 ---- n3 ---- n4
#  |       |       |       |       |
# n5 ---- n6 ---- n7 ---- n8 ---- n9
#  |       |       |       |       |
# n10---- n11---- n12---- n13---- n14
#  |       |       |       |       |
# n15---- n16---- n17---- n18---- n19
#  |       |       |       |       |
# n20---- n21---- n22---- n23---- n24
#  |       |       |       |       |
# n25---- n26---- n27---- n28---- n29
#  |       |       |       |       |
# n30---- n31---- n32---- n33---- n34
#  |       |       |       |       |
# n35---- n36---- n37---- n38---- n39
#  |       |       |       |       |
# n40---- n41---- n42---- n43---- n44
#  |       |       |       |       |
# n45---- n46---- n47---- n48---- n49


puts "\nytOSPF test 50 nodes ..."
cd [mkdir drcl.comp.Component /ospf_N50]

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e7; # 10Mbps

# Nodes:
puts "\nCreate nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.001;  # 1 msec
set adjMatrix_ [java::call drcl.inet.InetUtil createMeshAdjMatrix 5 10]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_
puts "Node build..."
$nb build [! n*] "ospf drcl.inet.protocol.ospf.OSPF"

# observe neighbor events
#watch -label NEIGHBOR -add n*/csl/.if@
#watch -label NEIGHBOR -add n0/csl/.if@

# simulator
puts "Attach simulator..."
set sim [attach_simulator event .]

puts "Setting debug flags for OSPF ..."
#setflag debug true n*/ospf
setflag debug true -at sample n0/ospf


# set area id
! n*/ospf ospf_set_area_id 1

#setflag trace true n0
# start OSPF
$sim stop
run n*

## first disable interface 0 of node 0 temporarily
script -at  100.0 -on $sim {cat n0}
script -at  100.0 -on $sim {puts "\nDisconnect link n0 -- n1 at 100.0 sim secs " }
script -at  100.0 -on $sim {setflag component false n0/0@/-/..} 
script -at  200.0 -on $sim {cat n0}
script -at  200.0 -on $sim {puts "\nRe-connect link n0 -- n1 at 200.0 sim secs "}
script -at  200.0 -on $sim {setflag component true n0/0@/-/..} 
#script -at  4.0 -on $sim {setflag trace true n0,n5 }
script -at  300.0 -on $sim {cat n0}
$sim stopAt 300.0
script {puts [$sim getTime]} -period 10.0 -on $sim
$sim resume
puts "Done ........"
