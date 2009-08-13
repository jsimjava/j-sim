# inetutil1.tcl
#
# Testing drcl.inet.InetUtil.configureFlat() with DV
#
# Physical Topology:
# h0 ----\
# h2 -----\            n10001
# h5 ------\          /   |
# h11 ------\        /    |
# h32 -------+-- n512     |
# h45 -------|       \    |
# h78 ------/         \   |
# h111 ----/           n10002
# h159 ---/
# h269 --/
#
# At the end of simulation, print out info with "cat n*"
#

cd [mkdir drcl.comp.Component /test]

puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set adjMatrix_ [java::new {int[][]} 13 {10 10 10 10 10 10 10 10 10 10 {0 1 2 3 4 5 6 7 8 9 11 12} {10 12} {10 11}}]
set ids_ [java::new {long[]} 13 {0 2 5 11 32 45 78 111 159 269 512 10001 10002}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $ids_ $link_

puts "build..."
set nb [mkdir drcl.inet.NodeBuilder .nb]
$nb build [! h*]
$nb build [! n*] {
	dv drcl.inet.protocol.dv.DV
}
java::call drcl.inet.InetUtil configureFlat [! .] false true;

set sim [attach_simulator event .]
$sim stop
script {cat n*} -at 200 -on $sim
run .
$sim resumeTo 200
