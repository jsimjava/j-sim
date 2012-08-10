#!/usr/bin/python2
# @(#)runtest.py   1/2004
# Copyright (c) 1998-2004, Distributed Real-time Computing Lab (DRCL) 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
# 3. Neither the name of "DRCL" nor the names of its contributors may be used
#    to endorse or promote products derived from this software without specific
#    prior written permission. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import sys, os, string, filecmp

SCRIPT_LIST_FILE = 'tclscript.lst'


""" print usage
"""
def usage():
	print 'usage: %(program)s command args' % {'program' : sys.argv[0]}
	print '- create trace files and save them in a directory \'dir\'.'
	print '\t %(program)s trace dir' % {'program' : sys.argv[0]}
	print '- compare two trace directories.'
	print '\t %(program)s diff dir1 dir2' % {'program' : sys.argv[0]}
	print '- compare two trace files.'
	print '\t %(program)s diff f1 f2' % {'program' : sys.argv[0]}


""" check python version
"""
def check_python_version():
	version = sys.version
	build_no = string.atoi(version[0])
	if not build_no == 2:
		print 'please upgrade Python'
		print 'current version: ' + version
		sys.exit()


""" create trace files and save them at a target directory
"""
def trace(target):
	# create output directory
	rootdir = os.getcwd()
	tracedir = os.path.join(rootdir, target)
	if not os.path.exists(tracedir):
		os.mkdir(tracedir)

	# get tcl script list
	f = open(SCRIPT_LIST_FILE, 'r')
	scripts = f.readlines()
	f.close()

	# get java path
	# spawnvpe is not supported in MS Windows
	java = os.path.join(os.path.join(os.getenv('JAVA_HOME'), 'bin'), 'java')

	# run script file
	for line in scripts:
		tclfile = string.strip(line)

		# if not marked as inactive
		if not tclfile[0] == '#':
			tracefile = os.path.join(tracedir, \
				os.path.basename(tclfile) + '.trace')

			os.chdir(os.path.dirname(tclfile))
			print ' - running: ' + os.path.basename(tclfile)
			run_args = ['java', 'drcl.ruv.System', '-ue', os.path.basename(tclfile), \
				'-testout', tracefile]
			os.spawnve(os.P_WAIT, java, run_args, os.environ)
			os.chdir(rootdir)


""" compare trace files in two directories
"""
def cmpdir(dir1, dir2):
	# get file lists
	files1 = os.listdir(dir1)
	files2 = os.listdir(dir2)

	# compare files in the directories
	common = []
	onlydir1 = []
	onlydir2 = []
	for f in files1:
		if files2.count(f) > 0:
			common.append(f)
		else:
			onlydir1.append(f)
	for f in files2:
		if files1.count(f) == 0:
			onlydir2.append(f)

	[match, mismatch, errors] = filecmp.cmpfiles(dir1, dir2, common)

	# print comparison results
	print "match", "-" * 44
	if len(match) > 0:
		for f in match:
			print ' -', f
	else:
		print ' none'
	print
	print "mismatch", "-" * 41
	if len(mismatch) > 0:
		for f in mismatch:
			print ' -', f
	else:
		print ' none'
	print

	if len(onlydir1) > 0:
		print 'file(s) only in', dir1, '-' * (33-len(dir1))
		for f in onlydir1:
			print ' -', f
	if len(onlydir2) > 0:
		print 'file(s) only in', dir2, '-' * (33-len(dir2))
		for f in onlydir2:
			print ' -', f
	print


def main():
	check_python_version()
	if len(sys.argv) < 3:
		usage()
		sys.exit()
	elif len(sys.argv) == 3 and sys.argv[1] == 'trace':
		print 'create new trace files in', sys.argv[2]
		trace(sys.argv[2])
	elif len(sys.argv) == 4 and sys.argv[1] == 'diff':
		# for file comparison
		if os.path.isfile(sys.argv[2]) and os.path.isfile(sys.argv[3]):
			print
			print 'trace files', '-' * 39
			print ' -', sys.argv[2]
			print ' -', sys.argv[3]
			print
			if filecmp.cmp(sys.argv[2],sys.argv[3]) == 1:
				print 'match'
			else:
				print 'mismatch'
			print
		# for directory comparison
		elif os.path.isdir(sys.argv[2]) and os.path.isdir(sys.argv[3]):
			print
			print 'trace directories', '-' * 32
			print ' -', sys.argv[2]
			print ' -', sys.argv[3]
			print
			cmpdir(sys.argv[2], sys.argv[3])
		else:
			usage()
	else:
		usage()

if __name__ == '__main__':
	main()

# Written by Hyuk Lim (hyuklim@uiuc.edu) on Jan 26, 2004
