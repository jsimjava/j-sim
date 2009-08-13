# DVMRP3.tcl
#
# Build a hierarchical network for testing DVMRP

cd [mkdir drcl.comp.Component /test]

puts "node builders..."
set rb [mkdir drcl.inet.NodeBuilder .routerBuilder];
$rb setBandwidth 8000
set hb [cp $rb .hostBuilder]
$rb loadmap "dvmrp drcl.inet.protocol.dvmrp.DVMRP"
mkdir $hb/.service_mcast@

# .net2_0:
# h1 --\         |
#       >-- n0 --+ 0@ 
# h2 --/         |
puts "build net2_0..."
cd [mkdir drcl.inet.Network .net2_0]
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set existing_  [!! [java::null] [java::null] [java::null] .]
set adjMatrix_ [java::new {int[][]} 4 {{1 2 3} {0} {0} {0}}]
java::call drcl.inet.InetUtil createTopology [! .] $existing_ $adjMatrix_ $link_ false
$rb build [! n0]
$hb build [! h*]
cd ..

# .net2_1:
# h1 --\          /--+ 0@
#       >-- n0 --<   |
# h2 --/          \--+ 1@
puts "build net2_1..."
cd [mkdir drcl.inet.Network .net2_1]
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set existing_  [!! [java::null] [java::null] [java::null] . .]
set adjMatrix_ [java::new {int[][]} 5 {{1 2 3 4} {0} {0} {0} {-1 0}}] 
java::call drcl.inet.InetUtil createTopology [! .] $existing_ $adjMatrix_ $link_ false
$rb build [! n0]
$hb build [! h*]
cd ..

# .net4:
# .net2_0 --\          /--+ 0@
#            >-- n0 --<   |
# .net2_1 --/          \--+ 1@
puts "build net4..."
cd [mkdir drcl.inet.Network .net4]
cp ../.net2_0 -d net2_0 net2_1
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set existing_  [!! [java::null] net2_0 net2_1 . .]
set adjMatrix_ [java::new {int[][]} 5 {{1 2 3 4} {0} {0} {0} {-1 0}}] 
java::call drcl.inet.InetUtil createTopology [! .] $existing_ $adjMatrix_ $link_ false
$rb build [! n0]
cd ..

# .net5:
# .net4 ------+ 0@
#       \     |
#        |    |
#        /    |
# .net2_1 ----+ 1@
puts "build net5..."
cd [mkdir drcl.inet.Network .net5]
cp ../.net2_1 net2
cp ../.net4 net4
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set existing_  [!! . net4 net2]
set adjMatrix_ [java::new {int[][]} 3 {{1 2} {0 2} {0 1}}]
java::call drcl.inet.InetUtil createTopology [! .] $existing_ $adjMatrix_ $link_
cd ..

# .net6:
# /---------\          /---------\
# |         + 0@ -- 1@ +         |
# | .net5_0 |          | .net5_1 |
# |         + 1@ -- 0@ +         |
# \---------/          \---------/
puts "build the testbed..."
cd [mkdir drcl.inet.Network testbed]
cp ../.net5 -d net5_1 net5_2
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set existing_  [!! net5_1 net5_2 net5_2]
set adjMatrix_ [java::new {int[][]} 3 {{1 2} {-1 0} {0}}]
java::call drcl.inet.InetUtil createTopology [! .] $existing_ $adjMatrix_ $link_
cd ..

puts "assign CIDR addresses..."
cd testbed
java::call drcl.inet.InetUtil setAddressByCIDR [! .]
java::call drcl.inet.InetUtil setIDByAddress [! .]

puts "configuring the network..."
java::call drcl.inet.InetUtil configure [! .]

puts "simulator..."
set sim [attach_simulator event .]

puts "start the simulation..."
$sim stop
run .

#setflag garbagedisplay true recursively .
watch -c -label FC -add {.../n*/csl/.rt_mcast@}
setflag debug true -at {debug_route debug_timeout debug_mcast_query debug_prune debug_graft} .../dvmrp
source DVMRP_common.tcl
