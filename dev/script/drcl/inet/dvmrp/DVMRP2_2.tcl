# DVMRP2_2.tcl
#
# Test drcl.inet.protocol.dvmrp.DVMRP on a virtual topology:
# 1. Route exchange and ucast routes adapt to topology change (link failure)
# 2. Prune and graft
# 3. Existing mcast tree adapts to topology change (link failure)
#
# Topology:
# n0 --\   ___/----- n8
#  |    \ /          /
#  \  ___X          /
#   \/    \        /
#  n50 -- n51 -- n52
#   /       \ ___/\
#  /      ___X     \
# n16 ----/    \-- n24
#
# Virtual Topology:
# n0 -------- n8
# |\           |
# | \--------\ |
# |           \|
# n16 ------- n24
#

set DVMRP2_VIRTUAL ""
source DVMRP2.tcl

#===============================================
script -at   50.0 -on $sim {puts ">>>>> Time 50.0: Stabilized routes:\n[cat n*/dvmrp]"}
script -at  100.0 -on $sim {puts ">>>>> Time 100.0: The link between n0 and n50 fails."}
script -at  100.0 -on $sim {setflag component false n0/0@/-/..}
script -at  160.0 -on $sim {puts ">>>>> Time 160.0: Transitional state after link failure:\n[cat n*/dvmrp]"}
script -at  220.0 -on $sim {puts ">>>>> Time 220.0: Stabilized routes after link failure:\n[cat n*/dvmrp]"}
script -at  270.0 -on $sim {puts ">>>>> Time 270.0: DV's at n0 and n50 are about to discover NEIGHBOR-DOWN."}
script -at  270.0 -on $sim { setflag debug true -at "debug_timeout debug_route" n*/dv }
script -at  280.0 -on $sim {puts ">>>>> Time 280.0: DV's have adapted themselves to the new topology."}
script -at  280.0 -on $sim { setflag debug false n*/dv }
script -at  280.0 -on $sim {puts ">>>>>             The virtual topology starts changing back due to the recovery of unicast routes."}
script -at  300.0 -on $sim {puts ">>>>> Time 300.0: Stablized routes after link recovery:\n[cat n*/dvmrp]"}
script -at  349.0 -on $sim {puts ">>>>> Time 350.0: Simulation stops.  Resume for testing prune and graft."}
#$sim stopAt 349.9
#===============================================
script -at  350.0 -on $sim {puts ">>>>> Time 350.0: Recover the link between n0 and n50."}
script -at  350.0 -on $sim {puts "                  (Just for restoring the original topology, does not affect DVMRP's.)"}
script -at  350.0 -on $sim {setflag component true n0/0@/-/..}
script -at  350.0 -on $sim { setflag debug true -at "debug_timeout debug_route" n*/dv }
script -at  380.0 -on $sim { setflag debug false n*/dv }
#$sim stopAt 399.0
#===============================================
script -at  400.0 -on $sim {puts ">>>>> Time 400.0: Inject a mcast packet at n16/csl/100@up to group -111."}
script -at  400.0 -on $sim {
	mkdir n0-24/csl/100@up
	send_mcast_pkt -message "To Group -111, #1" -from n16/csl/100@up -to -111 -size 1024
}
script -at  420.0 -on $sim {puts ">>>>> Time 420.0: Forwarding cache entries after prunes:\n[cat n0-24/csl/rt]"}
script -at  420.0 -on $sim {puts ">>>>> Time 420.0: Join group -111 at n0 and n8."}
script -at  420.0 -on $sim {host_event -join -111 -router n0/5@ -host none -router n8 -host none }
script -at  430.0 -on $sim {puts ">>>>> Time 430.0: Forwarding cache entries after grafts:\n[cat n0-24/csl/rt]"}
script -at  449.0 -on $sim {puts ">>>>> Time 450.0: Simulation stops.  Resume for testing another link failure."}
#$sim stopAt 450.0
#===============================================
script -at  470.0 -on $sim {puts ">>>>> Time 470.0: Leave group -111 at n0."}
script -at  470.0 -on $sim {host_event -leave -111 -router n0/5@ -host none}
script -at  480.0 -on $sim {puts ">>>>> Time 480.0: Inject a mcast packet at n16/csl/100@up to group -111."}
script -at  480.0 -on $sim {
	watch -c -label ROUTER_8 -add n8/csl/100@up
	send_mcast_pkt -message "To Group -111, #2" -from n16/csl/100@up -to -111 -size 1024
}
script -at  500.0 -on $sim {puts ">>>>> Time 500.0: Forwarding cache entries after prunes:\n[cat n0-24/csl/rt]"}
script -at  510.0 -on $sim {puts ">>>>> Time 510.0: The link between n8 and n52 fails."}
script -at  510.0 -on $sim {
	setflag component false n8/1@/-/..
	setflag debug true -at debug_sync_fc n*/dvmrp
}
script -at  630.0 -on $sim {puts ">>>>> Time 630.0: Stabilized routes after link failure:\n[cat n*/dvmrp]"}
script -at  640.0 -on $sim {puts ">>>>> Time 650.0: Forwarding cache entries after link failure:\n[cat n0-24/csl/rt]"}
script -at  650.0 -on $sim {puts ">>>>> Time 650.0: Inject a mcast packet at n16/csl/100@up to group -111."}
script -at  650.0 -on $sim {
	send_mcast_pkt -message "To Group -111, #3" -from n16/csl/100@up -to -111 -size 1024
}
script -at  670.0 -on $sim {puts ">>>>> Time 670.0: Forwarding cache entries after prunes:\n[cat n0-24/csl/rt]"}
script -at  674.0 -on $sim {puts ">>>>> Time 674.0: DV's have adapted themselves to the new topology."}
script -at  674.0 -on $sim {puts ">>>>>             The virtual topology starts changing back due to the recovery of unicast routes."}
script -at  674.0 -on $sim {puts ">>>>>             But this does not affect the multicast tree for group -111."}
script -at  749.0 -on $sim {puts ">>>>> Time 750.0: Forwarding cache entries after the virtual topology is recovered:\n[cat n0-24/csl/rt]"}
script -at  749.0 -on $sim {puts ">>>>> Time 750.0: ~~~~~~~~~ The End ~~~~~~~~~"}
$sim stopAt 750.0
#===============================================
$sim resume
