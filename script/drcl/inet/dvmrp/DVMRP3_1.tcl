# DVMRP3_1.tcl
#
# Test drcl.inet.protocol.dvmrp.DVMRP on a hierarchical network:
# 1. Route exchange and ucast routes adapt to topology change (link failure)
# 2. Prune and graft
# 3. Existing mcast tree adapts to topology change (link failure)
#

source DVMRP3.tcl

#===============================================
script -at   50.0 -on $sim {puts ">>>>> Time 50.0: Stabilized routes:\n[cat .../dvmrp]"}
script -at  100.0 -on $sim {puts ">>>>> Time 100.0: A link between n0_32 and n32_32 fails."}
script -at  100.0 -on $sim {setflag component false net0_32/0@/-/..}
script -at  160.0 -on $sim {puts ">>>>> Time 160.0: Transitional state after link failure:\n[cat .../dvmrp]"}
script -at  220.0 -on $sim {puts ">>>>> Time 220.0: Stabilized routes after link failure:\n[cat .../dvmrp]"}
script -at  250.0 -on $sim {puts ">>>>> Time 250.0: The link failure is recovered."}
script -at  250.0 -on $sim {setflag component true net0_32/0@/-/..}
script -at  280.0 -on $sim {puts ">>>>> Time 280.0: Stablized routes after link recovery:\n[cat .../dvmrp]"}
script -at  349.0 -on $sim {puts ">>>>> Time 350.0: Simulation stops.  Resume for testing prune and graft."}
#$sim stopAt 350.0
#===============================================
script -at  400.0 -on $sim {puts ">>>>> Time 400.0: Inject a mcast packet at .../h0/csl/100@up to group -111."}
script -at  400.0 -on $sim {
	mkdir .../h*/csl/100@up
	send_mcast_pkt -message "To Group -111, #1" -from .../h0/csl/100@up -to -111 -size 1024
}
script -at  420.0 -on $sim {puts ">>>>> Time 420.0: Forwarding cache entries after prunes:\n[cat .../rt]"}
script -at  420.0 -on $sim {puts ">>>>> Time 420.0: h32 and h48 join group -111."}
#script -at  420.0 -on $sim {host_event -join -111 -router .../n50/0@ -host .../h48 -router .../n34/0@ -host .../h32 }
script -at  420.0 -on $sim {! .../h32,h48/csl/igmp join -111 }
script -at  430.0 -on $sim {puts ">>>>> Time 430.0: Forwarding cache entries after grafts:\n[cat .../rt]"}
script -at  449.0 -on $sim {puts ">>>>> Time 450.0: Simulation stops.  Resume for testing another link failure."}
#$sim stopAt 450.0
#===============================================
script -at  470.0 -on $sim {puts ">>>>> Time 470.0: h48 leaves group -111."}
#script -at  470.0 -on $sim {host_event -leave -111 -router .../n50/0@ -host .../h48}
script -at  470.0 -on $sim {! .../h48/csl/igmp leave -111 }
script -at  480.0 -on $sim {puts ">>>>> Time 480.0: Inject a mcast packet at .../h0/csl/100@up to group -111."}
script -at  480.0 -on $sim {
	watch -c -label HOST_32 -add .../h32/csl/100@up
	send_mcast_pkt -message "To Group -111, #2" -from .../h0/csl/100@up -to -111 -size 1024
}
script -at  500.0 -on $sim {puts ">>>>> Time 500.0: Forwarding cache entries after prunes:\n[cat .../rt]"}
script -at  510.0 -on $sim {puts ">>>>> Time 510.0: The other link between n0_32 and n32_32 fails."}
script -at  510.0 -on $sim {
	setflag component false net0_32/1@/-/..
	setflag debug true -at debug_sync_fc .../dvmrp
}
script -at  630.0 -on $sim {puts ">>>>> Time 630.0: Stabilized routes after link failure:\n[cat .../dvmrp]"}
script -at  640.0 -on $sim {puts ">>>>> Time 650.0: Forwarding cache entries after link failure:\n[cat .../rt]"}
script -at  650.0 -on $sim {puts ">>>>> Time 650.0: Inject a mcast packet at .../h0/csl/100@up to group -111."}
script -at  650.0 -on $sim {
	send_mcast_pkt -message "To Group -111, #3" -from .../h0/csl/100@up -to -111 -size 1024
}
script -at  670.0 -on $sim {puts ">>>>> Time 670.0: Forwarding cache entries after prunes:\n[cat .../rt]"}
script -at  699.0 -on $sim {puts ">>>>> Time 700.0: ~~~~~~~~~ The End ~~~~~~~~~"}
$sim stopAt 700.0
#===============================================
$sim resume
