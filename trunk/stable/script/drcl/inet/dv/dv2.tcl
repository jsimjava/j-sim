# DV2.tcl
# Testing hierarchical routing in DV

cd [mkdir drcl.comp.Component /test]

puts "node builders..."
set rb [mkdir drcl.inet.NodeBuilder .routerBuilder]; # includs DV
$rb setBandwidth 8000
set hb [cp $rb .hostBuilder];
$rb loadmap "dv drcl.inet.protocol.dv.DV"

# .net2_0:
# n1 --\         |
#       >-- n0 --+ 0@ 
# n2 --/         |
puts "build net2_0..."
cd [mkdir drcl.inet.Network .net2_0]
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set existing_  [!! [java::null] [java::null] [java::null] .]
set adjMatrix_ [java::new {int[][]} 4 {{1 2 3} {0} {0} {0}}]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $existing_ $adjMatrix_ $link_ false
$rb build [! n0]
$hb build [! n1-2]
cd ..

# .net2_1:
# n1 --\          /--+ 0@
#       >-- n0 --<   |
# n2 --/          \--+ 1@
puts "build net2_1..."
cd [mkdir drcl.inet.Network .net2_1]
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set existing_  [!! [java::null] [java::null] [java::null] . .]
set adjMatrix_ [java::new {int[][]} 5 {{1 2 3 4} {0} {0} {0} {-1 0}}] 
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $existing_ $adjMatrix_ $link_ false
$rb build [! n0]
$hb build [! n1-2]
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
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $existing_ $adjMatrix_ $link_ false
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
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $existing_ $adjMatrix_ $link_
cd ..

# .net6:
# /---------\          /---------\
# |         + 0@ -- 1@ +         |
# | .net5_0 |          | .net5_1 |
# |         + 1@ -- 0@ +         |
# \---------/          \---------/
puts "build net6..."
cd [mkdir drcl.inet.Network .net6]
cp ../.net5 -d net5_1 net5_2
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set existing_  [!! net5_1 net5_2 net5_2]
set adjMatrix_ [java::new {int[][]} 3 {{1 2} {-1 0} {0}}]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $existing_ $adjMatrix_ $link_
cd ..

puts "assign CIDR addresses..."
cd .net6
java::call drcl.inet.InetUtil setAddressByCIDR [! .]
java::call drcl.inet.InetUtil setIDByAddress [! .]

puts "simulator..."
set sim [attach_simulator event .]

puts "configuring the network..."
java::call drcl.inet.InetUtil configure [! .]

setflag debug true -at "debug_timeout debug_route" .../dv

puts "start the simulation..."
$sim stop
run .../n0-1000
script -at 20.0 {cat net*/.../rt} -on $sim
puts "done."
$sim resumeTo 20.001
