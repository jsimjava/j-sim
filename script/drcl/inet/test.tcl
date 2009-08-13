# test.tcl
#
# testing InetUtil.setupRoute()
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


cd [mkdir drcl.comp.Component /test]

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
java::call drcl.inet.InetUtil setupRoute [! n0] [! n1]
