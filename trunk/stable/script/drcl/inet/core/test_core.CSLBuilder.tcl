# test_core.CSLBuilder.tcl (CSL:CoreServiceLayer)
# This script tests all kinds of automation implemented in
# drcl.inet.core.CSLBuilder:
# 0. Auto creation of RT, Hello, PFS
# 1. Layout in build() 
# 2. extract() & build()

# net0: auto creation of RT, Hello, PFS
puts "Testing auto creation of RT, Hello and PFS"
cd [mkdir drcl.comp.Component /net0]
mkdir drcl.inet.core.CSLBuilder cb1 cb2 cb3
mkdir drcl.inet.core.PktFilter cb1/pf0 cb1/pf2_1
mkdir drcl.inet.core.queue.FIFO cb1/q
mkdir drcl.inet.core.CoreServiceLayer c1 c2 c3
mkdir c1/0@down c1/1@down c1/2@down
mkdir c1/[java::field drcl.inet.InetConstants SERVICE_ID_PORT_ID]@;
mkdir c2/[java::field drcl.inet.InetConstants SERVICE_IF_PORT_ID]@; # cause creation of c2/hello
mkdir c3/[java::field drcl.inet.InetConstants SERVICE_CONFIGSW_PORT_ID]@; # cause creation of c3/pfs
foreach i {1 2 3} {
	! cb$i build [! c$i]
}
puts "Result: (c1 contains id and rt; c2 contains hello; c3 contains pfs)\n[cat -cd c?]"

# net1: auto layout test
puts "Testing auto layout of differrent packet filter bank structures"
cd [mkdir drcl.comp.Component /net1]
set cb [mkdir drcl.inet.core.CSLBuilder builder]
cd $cb
mkdir drcl.inet.core.Hello hello
mkdir drcl.inet.core.queue.DropTail q
mkdir drcl.inet.core.PktFilter pf2
set pf0 [java::new drcl.inet.core.PktFilter]
! $pf0/up@ setType OUT
! $pf0/down@ setType IN
mkdir $pf0 pf0
set pf4 [java::new drcl.inet.core.PktFilter]
! $pf4/*@ setType IN&OUT
mkdir $pf4/[java::field drcl.inet.InetConstants SERVICE_ID_PORT_ID]@; # cause connection with id 
mkdir $pf4 pf4
mkdir drcl.inet.core.ni.PointopointNI ni
cd ..

mkdir drcl.inet.core.CoreServiceLayer c1 c2
mkdir c?/[java::field drcl.inet.InetConstants SERVICE_ID_PORT_ID]@;
connect -c c1/0@down -and c2/0@down
connect -c c1/1@down -and c2/2@down
$cb build [! c?]
puts "Result: (c1 and c2 have the same structure, here only shows c1's)\n[cat -cd c1]"

# net2: extract() & build() test
puts "Testing extract() & build()"
cd [mkdir drcl.comp.Component /net2]
mkdir drcl.inet.core.CoreServiceLayer c1 c2 c3
connect -c c1/0@down -and c2/1@down
connect -c c2/2@down -and c3/3@down
connect -c c3/0@down -and c1/3@down
set cb2 [mkdir drcl.inet.core.CSLBuilder builder]
$cb2 extract [! /net1/c1]
$cb2 build [! c?]
puts "Result: (c? have the same structure as ../net1/c1, here only shows c2'2)\n[cat -cd c2]"

# net3: performance test
set n 500; # number of CSL's
puts "Performance test: create, build and connect $n CoreServiceLayers."
cd [mkdir drcl.comp.Component /net3]
puts -nonewline "   create...";# 4.45 secs
set t [java::call System currentTimeMillis]
set all_ ""
for {set i 0} {$i < $n} {incr i} { append all_ "c$i " }
eval [subst -nocommands {mkdir drcl.inet.core.CoreServiceLayer $all_}]
puts "[java::call drcl.util.MiscUtil timeElapsed $t] sec"

puts -nonewline "   connect...";# 13.68 secs
set t [java::call System currentTimeMillis]
for {set i 0} {$i < $n} {incr i} {
	set next_ [expr {($i+1)%$n}]
	connect -c c$i/0@down -and c$next_/1@down
}
puts "[java::call drcl.util.MiscUtil timeElapsed $t] sec"
#puts "   follows...";# 13 secs
#! c* follows $core
puts -nonewline "   build...";# 2.64 secs
set t [java::call System currentTimeMillis]
$cb2 build [! c*]
puts "[java::call drcl.util.MiscUtil timeElapsed $t] sec"

puts Done!
exit
