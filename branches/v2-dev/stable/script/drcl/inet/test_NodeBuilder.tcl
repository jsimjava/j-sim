# test_NodeBuilder.tcl
# This script tests all kinds of automation implemented in
# drcl.inet.NodeBuilder and drcl.inet.core.CSLBuilder:
#
# net1: Layout in build() 
# net2: extract() & build()

set tester [mkdir drcl.comp.tool.ComponentTester tester]

# net1: layout test
puts "Testing layout"
cd [mkdir drcl.comp.Component /net1]
# CSLBuilder:
set cb [mkdir drcl.inet.core.CSLBuilder cb]
cd $cb
mkdir drcl.inet.core.queue.DropTail q
#                    pd
# --------------||-------------|------------
# any interface || interface 0 || interface 1
#   |    ^      ||   |   ^     ||   |   ^
#   |    |      ||   |   |     ||   |   |
#   |  (pf0)    ||(pf0_0)|     ||   | (pf0)
#   |    ^      ||   |   |     ||   V   ^
#   |    |      ||   |   |     ||(pf1_1)|
#   |    |      ||   |   |     ||   |   |
#   V    |      ||   V   |     ||   V   |
# (pf2)  |      || (pf2) |     || (pf2) |
#   |    |      ||   |   |     ||   |   |
#   V    |      ||   V   |     ||   V   |
#   (pf4)       ||   (pf4)     ||   (pf4) 
#   |    ^      ||   |   ^     ||   |   ^
#   V    |      ||   V   |     ||   V   |
#  (q)   |      ||  (q)  |     ||  (q1) |
#   |    |      ||   |   |     ||   |   |
#   V    |      ||   V   |     ||   V   |
#  (ni)  |      ||  (ni) |     ||  (ni) |
#   |    |      ||   |   |     ||   |   |
#   V    |      ||   V   |     ||   V   |
#   (down)      ||   (down)    ||  (down)
mkdir drcl.inet.core.PktFilter pf2
set pf0 [java::new drcl.inet.core.PktFilter]
! $pf0/up@ setType OUT
! $pf0/down@ setType IN
mkdir $pf0 pf0
set pf4 [java::new drcl.inet.core.PktFilter]
! $pf4/*@ setType IN&OUT
mkdir $pf4/[java::field drcl.inet.InetConstants SERVICE_ID_PORT_ID]@; # cause connection with id 
mkdir $pf4 pf4
mkdir drcl.comp.Component pf0_0 pf1_1
mkdir pf0_0/up@ pf1_1/up@ pf0_0/down@ pf1_1/down@
mkdir drcl.inet.core.ni.PointopointNI ni
mkdir drcl.comp.Component ext0
mkdir drcl.inet.Protocol ext1
mkdir ext0/.extension@ ext1/.extension@ ext0/.service_rt@ ext1/.service_rt@
mkdir drcl.inet.core.queue.FIFO q1
cd ..
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder nb]
cd $nb
mkdir drcl.inet.Protocol p1 p2
! p1 createIDServicePort
! p1 createRTServicePort
! p1 createMcastQueryPort
! p1 createIDChangedEventPort
! p2 createIFQueryPort
! p2 createUnicastRTChangedEventPort
! p2 createConfigSwitchPort
set app1 [mkdir drcl.comp.Component app1]
connect -c $app1/down@ -and p1/up@
set app2 [mkdir drcl.comp.Component app2]
connect -cs $app2/down@ -and p2/up@

# Nodes:
cd ..
puts "     Build..."
set adjMatrix_ [java::new {int[][]} 4 {{1 2 3} {0 3} {0 3} {0 1 2}}]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $adjMatrix_ [java::null]
$nb build [! n?] $cb

# net2: extract() & build() test
puts "Testing extract() & build()"
cd [mkdir drcl.comp.Component /net2]
set cb2 [mkdir drcl.inet.core.CSLBuilder cb2]
$cb2 extract [! /net1/n0/csl]
set nb2 [mkdir drcl.inet.NodeBuilder nb]
$nb2 extract [! /net1/n1]
puts "     Build..."
set adjMatrix_ [java::new {int[][]} 4 {{1 2 3} {0 3} {0 3} {0 1 2}}]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $adjMatrix_ [java::null]
$nb2 build [! n?] $cb2

# net3: performance test
puts "Performance test"
set n 500; # number of CSL's
cd [mkdir drcl.comp.Component /net3]
puts -nonewline "   create and connect...";# < 3 secs
set t [java::call System currentTimeMillis]
set adjMatrix_ ""
for {set i 0} {$i < $n} {incr i} {
	set prev_ [expr {($i+$n-1)%$n}]
	set next_ [expr {($i+1)%$n}]
	append adjMatrix_ "\{$prev_ $next_\} "
}
set adjMatrix_ [java::new {int[][]} $n $adjMatrix_]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_
puts "[java::call drcl.util.MiscUtil timeElapsed $t] sec"

setflag errorNotice false $nb2/p?
puts -nonewline "   build...";# ~ 6 secs
$nb2 build [! n*] $cb
puts "[java::call drcl.util.MiscUtil timeElapsed $t] sec"

puts Done!
