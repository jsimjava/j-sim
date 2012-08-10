#
# This tcl file should be included in each test tcl file to specify
# the path of the trace file
#

# 1) include this script "include.tcl" in the beginning of your tcl file
#    example: "source ../../../test/include.tcl"
set testflag 0
if { $argc > 0 } {
	set testout [lsearch -exact $argv "-testout"]
	if { $testout != -1 } {
		set testflag 1
   	 	set filename [lindex $argv [expr $testout+1]]
		set testfile [mkdir drcl.comp.io.FileComponent .testtrace]
		$testfile open $filename
	}
}

# 2) attach the trace file port to *****
#    example: "if { $testflag } {
#                  attach -c $testfile/in@ -to *****
#              }"
