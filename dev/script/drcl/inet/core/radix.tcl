# radix.tcl
#
# Testing drcl.data.RadixMap

set ifs [java::new drcl.data.BitSet [java::new {int[]} 3 {0 2 4}]]
set entry [java::new drcl.inet.data.RTEntry $ifs "Hello!"]
set key [java::new drcl.inet.data.RTKey 100 100 100]

set map [java::new drcl.data.RadixMap]

