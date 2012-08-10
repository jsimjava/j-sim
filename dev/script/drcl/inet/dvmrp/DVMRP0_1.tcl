# DVMRP0_1.tcl
#
# Test the core/edge interfacees
# using the topology in DVMRP0_1.tcl.
# Each router should contain only 4 external routing entries.
# This example can be seen as a 2-level (host + router) hierarchical network.
#
# Topology (from DVMRP0_1.tcl):
# n0 --\   ___/----- n2
#  |    \ /          /
#  |  ___X          /
#   \/    \        /
#   n8 --- n9 --- n10
#   /       \ ___/\
#  /      ___X     \
# n4 ----/    \--- n6
#
# Nodes n8-10 have only core interfaces. 

set DVMRP0_CALLED_PHYSICAL_ONLY ""
source DVMRP0.tcl

run n*
script {cat n*/dvmrp} -at 200.0 -on $sim
$sim stopAt 201.0


