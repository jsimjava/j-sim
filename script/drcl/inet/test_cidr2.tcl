# test_cidr2.tcl
# Example 3 in the INET doc, Part II.

cd [mkdir drcl.comp.Component scene]

set link_ [java::new drcl.inet.Link]
# Build .LAN3, level-2 network
mkdir drcl.inet.Network .LAN3
set adjMatrix_ [java::new {int[][]} 4 {{1 2 3} 0 0 0}]
java::call drcl.inet.InetUtil createTopology [! .LAN3] $adjMatrix_ $link_
connect -c .LAN3/0@ -and .LAN3/n0/3@

# Build .LAN4, level-2 network
mkdir drcl.inet.Network .LAN4
set adjMatrix_ [java::new {int[][]} 5 {{1 2 3 4} 0 0 0 0}]
java::call drcl.inet.InetUtil createTopology [! .LAN4] $adjMatrix_ $link_
connect -c .LAN4/0@ -and .LAN4/n0/4@

# Build .net0, level-1 network
mkdir drcl.inet.Network .net0
cp .LAN4 -d .net0/net10 .net0/net12
cp .LAN3 .net0/net11
cd .net0
# index: n0, n1, n2, 3-net10, 4-net11, 5-net12
# n0, n1 and n2 are to be created
set existing_ [!! [java::null] [java::null] [java::null] net10 net11 net12]
set adjMatrix_ [java::new {int[][]} 6 {{1 2} {0 2 3} {0 1 4 5} 1 2 2}]
java::call drcl.inet.InetUtil createTopology [! .] $existing_ $adjMatrix_ $link_
connect -c ./0@ -and n0/2@
cd ..

# Build the final, level-0 network
cp .net0 -d net00 net01 net02 net03
# index: n0, n1, n2, 3-net00, 4-net01, 5-net02, 6-net03
# n0, n1, n2 are to be created
set existing_ [!! [java::null] [java::null] [java::null] net00 net01 net02 net03]
set adjMatrix_ [java::new {int[][]} 7 {{1 2 6} {0 2 3} {0 1 4 5} 1 2 2 0}]
java::call drcl.inet.InetUtil createTopology [! .] $existing_ $adjMatrix_ $link_

puts "Build nodes..."
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
mkdir $nb/.if@; # so that it will build interface info below
$nb build [!! net?? n?]
java::call drcl.inet.InetUtil setAddressByCIDR [!! net?? n?]
java::call drcl.inet.InetUtil setIDByAddress [!! net?? n?]

puts "Configuring..."
java::call drcl.inet.InetUtil configure [!! net* n???]

puts "done"
