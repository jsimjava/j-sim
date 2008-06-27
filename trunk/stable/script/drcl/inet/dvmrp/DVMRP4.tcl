# DVMRP4.tcl
#
# same toplogy as DVMRP0.tcl except we use drcl.inet.InetUtil.configureFlat()
# to automatically configure the interface info on the routers (n0, n2, n4 and
# n6)
#
# Topology:
# n0 --\   ___/----- n2
#  |    \ /          /
# (x) ___X          /
#   \/    \        /
#   n8 --- n9 --- n10
#   /       \ ___/\
#  /      ___X     \
# n4 ----/    \--- n6
#
# Link failure:
# 201.0: the link (marked "x") between n0 and n8 fails.
#
# Observations by "cat n*/.../dvmrp"
# At time 300.0: routes between n0 and n2,n4 are broken
# At time 500.0: alternative routes are discovered using n9/n10 as bridge

cd [mkdir drcl.comp.Component /test]

# Nodes:
puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set adjMatrix_ [java::new {int[][]} 11 {{8 9 1} {0} {8 10 3} {2} {8 10 5} {4} {9 10 7} {6} {0 2 4 9} {0 6 8 10} {2 4 6 9}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder];
puts "build..."
$nb build [! h*]
$nb build [! n*] {
	dv 		drcl.inet.protocol.dv.DV
	dvmrp 	drcl.inet.protocol.dvmrp.DVMRP
}

puts "Configuring interfaces..."
java::call drcl.inet.InetUtil configureFlat [! n0,n2,n4,n6]
# configureFlat may re-assign node IDs but in this case, node IDs are
# preserved 

# simulator
puts "simulator..."
set sim [attach_simulator .]

#setflag trace true n8; # watch initially dropped packet-in-packets 


setflag debug true -at "debug_timeout debug_route" n*/dvmrp

# start DV/DVMRP
puts "Simulation starts..."
run n*
script -at  200.0 {puts [cat n*/.../dvmrp]} -on $sim
script -at  200.0 {setflag component false n0/0@/-/..} -on $sim
script -at  300.0 {puts [cat n*/.../dvmrp]} -on $sim
script -at  500.0 {puts [cat n*/.../dvmrp]} -on $sim
$sim stopAt 501.0
