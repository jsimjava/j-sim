# cbt.tcl
#
# Testing drcl.inet.protocol.cbt.CBT
#
# Topology:
# h1-\
# h2--+n0 --\   /----------- n8- h9
#       |    \ /              |
#       \  ___X               |
#        \/    \              |
#       n50 -- n51 -- n52 -- n53
#        / \  /               |
#       /   -+----\           |
# h17--n16 -/      \-------- n24- h25
#
# Core: n52
# - time 0.0: n1, n2 and n17 joins
# - time 20.0: n9 joins
# - time 30.0: n25 sends data to the mcast group
# - time 40.0: n25 joins
# - time 60.0: n1 and n2 leaves
# - time 80.0: n9 and n25 leaves
# - time 100.0: n17 leaves

source "../../../test/include.tcl"

cd [mkdir drcl.comp.Component /test]

# some constants
set core 52;    # core address
set group -101; # multicast group

puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.02
set adjMatrix_ [java::new {int[][]} 13 {
				{1 2 3 6}
				0
				0
				{0 4 6 9 11}
				{3 5 6}
				4
				{0 3 4 7}
				{6 8}
				{7 9 11}
				{3 8 10}
				9
				{3 8 12}
				11
		}]
		

set ids_ [java::new {long[]} 13 {0 1 2 50 16 17 51 52 53 8 9 24 25}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $ids_ $link_

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder];
puts "build..."
$nb build [! n*] "cbt 101/csl drcl.inet.protocol.cbt.CBT"
$nb build [! h*] "app 202/csl drcl.inet.application.McastTestApp"

puts "set up unicast routes"
java::call drcl.inet.InetUtil setupRoutes [! .] $adjMatrix_ $ids_

# configure CBT
java::call drcl.inet.protocol.cbt.CBT addCore $group $core
watch -c -label FC -add n*/csl/.rt_mcast@

if { $testflag } {
	attach -c $testfile/in@ -to n*/csl/.rt_mcast@
}

# simulator
puts "simulator..."
set sim [attach_simulator event .]
$sim stop
run n*

script {! h1,h2,h17/app join $group} -at 0.0 -on $sim
script {! h9/app join $group} -at 20.0 -on $sim
script {! h25/app send $group "test_data" 1300} -at 30.0 -on $sim
script {! h25/app join $group} -at 40.0 -on $sim
script {! h2/app send $group "test_data_2" 1100} -at 50.0 -on $sim
script {! h1,h2/app leave $group} -at 60.0 -on $sim
script {! h9,h25/app leave $group} -at 80.0 -on $sim
script {! h1/app send $group "test_data_3" 1200} -at 90.0 -on $sim
script {! h17/app leave $group} -at 100.0 -on $sim

#setflag debug true -at {debug_route debug_timeout debug_io debug_state} n*/cbt

if { $testflag } {
    script "exit" -at 200 -on $sim
}

$sim resumeTo 200.0
