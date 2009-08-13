# ytOSPFn100.tcl
#
# Modified by Youngtak Kim to test scalability
#  with OSPF routing protocol
# Topology : 10 x 10 mesh
# Topology:
# n0---n1---n2---n3---n4---n5---n6---n7---n8---n9
#  |    |    |    |    |    |    |    |    |    |
# n10--n11--n12--n13--n14--n15--n16--n17--n18--n19 
#  |    |    |    |    |    |    |    |    |    |
# n20--n21--n22--n23--n24--n25--n26--n27--n28--n29 
#  |    |    |    |    |    |    |    |    |    |
# n30--n31--n32--n33--n34--n35--n36--n37--n38--n39 
#  |    |    |    |    |    |    |    |    |    |
# n40--n41--n42--n43--n44--n45--n46--n47--n48--n49 
#  |    |    |    |    |    |    |    |    |    |
# n50--n51--n52--n53--n54--n55--n56--n57--n58--n59 
#  |    |    |    |    |    |    |    |    |    |
# n60--n61--n62--n63--n64--n65--n66--n67--n68--n69 
#  |    |    |    |    |    |    |    |    |    |
# n70--n71--n72--n73--n74--n75--n76--n77--n78--n79 
#  |    |    |    |    |    |    |    |    |    |
# n80--n81--n82--n83--n84--n85--n86--n87--n88--n89 
#  |    |    |    |    |    |    |    |    |    |
# n90--n91--n92--n93--n94--n95--n96--n97--n98--n99 


cd [mkdir drcl.comp.Component /OSPFtest]

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e7; #10Mbps

# Nodes:
puts "\nCreate nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.02;  # 20 msecs
set adjMatrix_ [java::call drcl.inet.InetUtil createMeshAdjMatrix 10 10]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $adjMatrix_ $link_
puts "Node build..."
$nb build [! n*] "ospf drcl.inet.protocol.ospf.OSPF"

# observe neighbor events
#watch -c -label NEIGHBOR -add n*/csl/.if@
#watch -c -label NEIGHBOR -add n0/csl/.if@

# simulator
puts "Attach simulator..."
set sim [attach_simulator .]

puts "Setting debug flags for OSPF ..."
#setflag debug true n*/ospf
setflag debug true -at sample n0/ospf

# set area id
! n*/ospf ospf_set_area_id 1


# start OSPF
$sim stop
run n*

## first disable interface 0 of node 0 temporarily
#script -at  300.0 -on $sim {puts "\nDisconnect link n0 -- n1 at 30.0 sim secs " }
#script -at  300.0 -on $sim {setflag component false n0/0@/-/..} 
#script -at  400.0 -on $sim {puts "\nRe-connect link n0 -- n1 at 200.0 sim secs "}
#script -at  400.0 -on $sim {setflag component true n0/0@/-/..} 
$sim stopAt 300.0
puts "Done ........."
script {puts [$sim getTime]} -period 10.0 -on $sim
$sim resume
