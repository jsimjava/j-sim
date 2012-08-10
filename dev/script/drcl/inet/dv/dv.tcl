# DV.tcl
#
# Topology:
# n0 --------- n1
# |\           |
# | \--------\ |
# |           \|
# n2 --------- n3

source "../../../test/include.tcl"

cd [mkdir drcl.comp.Component /test]

# Nodes:
puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set adjMatrix_ [java::new {int[][]} 4 {{1 2 3} {3 0} {0 3} {0 1 2}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 8000
puts "build..."
$nb build [! n?] "dv drcl.inet.protocol.dv.DV"

# observe route change events
watch -c -label RT -add n?/csl/.rt_ucast@

if { $testflag } {
	attach -c $testfile/in@ -to n?/csl/.rt_ucast@
}

# simulator
puts "simulator..."
set sim [attach_simulator event .]

setflag debug true -at "debug_timeout debug_route" n?/dv

# start DV
$sim stop
run n?
script -at  50.0 {disconnect n0/0@} -on $sim
script -at 100.0 {setflag debug true -at debug_route n?/dv} -on $sim
script -at 350.0 {cat n?/.../rt} -on $sim
script -at 350.0 {connect n0/0@ -and .link0/0@} -on $sim
script -at 600.0 {cat n?/.../rt} -on $sim

$sim stopAt 600.0
puts "------------- DONE ----------------"
$sim resume

