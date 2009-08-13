# DVMRP1.tcl
#
# Test drcl.inet.protocol.dvmrp.DVMRP on a simple topology:
# 1. Route exchange and ucast routes adapt to topology change (link failure)
# 2. Prune and prune timeout
# 3. Prune and graft
# 4. Existing mcast tree adapts to topology change (link failure)
#
# Topology:
# n0 --------- n8
# |\           |
# | \--------\ |
# |           \|
# n16 -------- n24

cd [mkdir drcl.comp.Component /test]

# Nodes:
puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set adjMatrix_ [java::new {int[][]} 4 {{1 2 3} {3 0} {0 3} {0 1 2}}]
set ids_ [java::new {long[]} 4 {0 8 16 24}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $ids_ $link_

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 8000
puts "build..."
$nb build [! n*] "dvmrp drcl.inet.protocol.dvmrp.DVMRP"

puts "Configuring interfaces..."
for {set i 0} {$i < 3} {incr i} {
	! n0 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 0 -8]
	! n24 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 24 -8]
}
for {set i 0} {$i < 2} {incr i} {
	! n8 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 8 -8]
	! n16 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 16 -8]
}

# simulator
puts "simulator..."
set sim [attach_simulator event .]

puts "Simulation starts..."
source DVMRP_common.tcl
setflag debug true -at {debug_route debug_timeout debug_mcast_query debug_prune debug_graft} n*/dvmrp
watch -c -label FC -add n*/csl/.rt_mcast@

$sim stop
run n*

#===============================================
script -at   50.0 -on $sim {puts ">>>>> Time 50.0: Stabilized routes:\n[cat n*/dvmrp]"}
script -at  100.0 -on $sim {puts ">>>>> Time 100.0: The link between n0 and n8 fails."}
script -at  100.0 -on $sim {setflag component false n0/0@/-/..}
script -at  160.0 -on $sim {puts ">>>>> Time 160.0: Transitional state after link failure:\n[cat n*/dvmrp]"}
script -at  220.0 -on $sim {puts ">>>>> Time 220.0: Stabilized routes after link failure:\n[cat n*/dvmrp]"}
script -at  250.0 -on $sim {puts ">>>>> Time 250.0: The link failure is recovered."}
script -at  250.0 -on $sim {setflag component true n0/0@/-/..}
script -at  260.0 -on $sim {puts ">>>>> Time 260.0: Stablized routes after link recovery:\n[cat n*/dvmrp]"}
script -at  349.0 -on $sim {puts ">>>>> Time 350.0: Simulation stops.  Resume for testing broadcast, prune and prune timeout."}
#$sim stopAt 350.0
#===============================================
script -at  400.0 -on $sim {puts ">>>>> Time 400.0: Inject a mcast packet at n16/csl/100@up to group -111."}
script -at  400.0 -on $sim {
	mkdir n*/csl/100@up
	! n0/dvmrp setPruneLifetime 20
	setflag garbagedisplay true recursively n*/csl
	send_mcast_pkt -message "To Group -111" -from n16/csl/100@up -to -111 -size 1024
}
script -at  420.0 -on $sim {puts ">>>>> Time 420.0: Forwarding cache entries after prunes:\n[cat n*/csl/rt]"}
script -at  440.0 -on $sim {puts ">>>>> Time 440.0: Forwarding cache entries after prune states are timed out:\n[cat n*/csl/rt]"}
script -at  449.0 -on $sim {puts ">>>>> Time 450.0: Simulation stops.  Resume for testing graft."}
#$sim stopAt 450.0
#===============================================
script -at  500.0 -on $sim {puts ">>>>> Time 500.0: Inject a mcast packet at n16/csl/100@up to group -111."}
script -at  500.0 -on $sim {
	! n0/dvmrp setPruneLifetime [expr 2*60*60]; # 2 hrs
	send_mcast_pkt -message "To Group -111, #1" -from n16/csl/100@up -to -111 -size 1024
}
script -at  520.0 -on $sim {puts ">>>>> Time 520.0: Forwarding cache entries after prunes:\n[cat n*/csl/rt]"}
script -at  520.0 -on $sim {puts ">>>>> Time 520.0: Join group -111 at n0 and n8."}
script -at  520.0 -on $sim {host_event -join -111 -router n0/5@ -host none -router n8 -host none }
script -at  530.0 -on $sim {puts ">>>>> Time 530.0: Forwarding cache entries after grafts:\n[cat n*/csl/rt]"}
script -at  549.0 -on $sim {puts ">>>>> Time 550.0: Simulation stops.  Resume for testing another link failure."}
#$sim stopAt 550.0
#===============================================
script -at  570.0 -on $sim {puts ">>>>> Time 570.0: Leave group -111 at n0."}
script -at  570.0 -on $sim {host_event -leave -111 -router n0/5@ -host none}
script -at  580.0 -on $sim {puts ">>>>> Time 580.0: Inject a mcast packet at n16/csl/100@up to group -111."}
script -at  580.0 -on $sim {
	watch -c -label ROUTER_8 -add n8/csl/100@up
	send_mcast_pkt -message "To Group -111, #2" -from n16/csl/100@up -to -111 -size 1024
}
script -at  600.0 -on $sim {puts ">>>>> Time 600.0: Forwarding cache entries after prunes:\n[cat n*/csl/rt]"}
script -at  610.0 -on $sim {puts ">>>>> Time 610.0: The link between n8 and n24 fails."}
script -at  610.0 -on $sim {
	setflag component false n8/0@/-/..
	setflag debug true -at debug_sync_fc n*/dvmrp
}
script -at  730.0 -on $sim {puts ">>>>> Time 730.0: Stabilized routes after link failure:\n[cat n*/dvmrp]"}
script -at  740.0 -on $sim {puts ">>>>> Time 750.0: Forwarding cache entries after link failure:\n[cat n*/csl/rt]"}
script -at  750.0 -on $sim {puts ">>>>> Time 750.0: Inject a mcast packet at n16/csl/100@up to group -111."}
script -at  750.0 -on $sim {
	send_mcast_pkt -message "To Group -111, #3" -from n16/csl/100@up -to -111 -size 1024
}
script -at  770.0 -on $sim {puts ">>>>> Time 770.0: Forwarding cache entries after prunes:\n[cat n*/csl/rt]"}
script -at  799.0 -on $sim {puts ">>>>> Time 800.0: ~~~~~~~~~ The End ~~~~~~~~~"}
$sim stopAt 800.0
#===============================================
$sim resume
