# QoS_OSPFn50.tcl
#
# Modified by Wei-peng Chen from Youngtak Kim to test QoS
# extension function of OSPF routing protocol
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

##################################################################
# Comments: by using "cat no/ospf", users can see all the values
# in QoS_RT

puts "\nQoS_OSPF test 50 nodes ..."
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
$nb build [! n*] "ospf drcl.inet.protocol.ospf.OSPF_QoS"

# observe neighbor events
#watch -label NEIGHBOR -add n*/csl/.if@
#watch -label NEIGHBOR -add n0/csl/.if@

# simulator
puts "Attach simulator..."
set sim [attach_simulator event .]

puts "Setting debug flags for OSPF ..."
#setflag debug true n*/ospf
setflag debug true -at sample n0/ospf
#setflag debug true -at spf n0/ospf
setflag debug true -at qos n0/ospf

# set area id
! n*/ospf ospf_set_area_id 1

# set QoS parameters, 40 is for bw
! n*/ospf set_QoS_options 40

#setflag trace true n0
# start OSPF
$sim stop
run n*

script -at  10.0 -on $sim {! n*/ospf set_periodical_precompute_options true 10}
script -at  20.1 -on $sim {! n0/ospf show_QoS_precompute_nexthop_by_bw 10 100} 
script -at  20.1 -on $sim {! n0/ospf show_QoS_ondemand_nexthop_by_bw 10 100} 

script -at  20.2 -on $sim {setflag debug true -at sample n6/ospf}
script -at  20.2 -on $sim {! n6/ospf show_QoS_precompute_nexthop_by_bw 12 100} 
script -at  20.2 -on $sim {! n6/ospf show_QoS_ondemand_nexthop_by_bw 12 100} 

$sim stopAt 30.0
script {puts [$sim getTime]} -period 10.0 -on $sim
$sim resume
puts "Done ........"
