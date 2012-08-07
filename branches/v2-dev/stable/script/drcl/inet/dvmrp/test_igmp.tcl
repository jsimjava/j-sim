# test_igmp.tcl
#

source DVMRP3.tcl

rt . resumeFor 100
cd net0_32/net0_16/net0_4

wait_until {rt . isStopped}

! h0-1/csl/igmp join -111
rt . resumeFor 2

wait_until {rt . isStopped}

! h0/csl/igmp leave -111
rt . resumeFor 2

