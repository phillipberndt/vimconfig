" Matlab plugin for VIM
" This plugin integrates Matlab with VIM
"
" Mappings in *.m files:
"  <F5>:   Execute current file in Matlab
"  <S-F5>: Execute a command entered by the user
"
" Commands:
"  MatlabDo foo    Execute foo in Matlab
"
"
"
" Copyright (c) 2012, Phillip Berndt
" Feel free to use this under the terms of the GNU Public License v3.
"

if exists("g:matlab_script_loaded")
	finish
end
let g:matlab_script_loaded = 1

py <<END
import re
import vim
import sys
import pexpect
import os
class matlabInterface:
	matlabInstance = None

	@staticmethod
	def startup():
		if matlabInterface.matlabInstance == None or not matlabInterface.matlabInstance.isalive():
			print "Starting MATLAB.."
			matlabInterface.matlabInstance = pexpect.spawn("matlab -nodesktop -nosplash")
			matlabInterface.matlabInstance.expect(">>")
			vim.command("echo ''")
	
	@staticmethod
	def showOutput():
		errors = []
		while True:
			what = matlabInterface.matlabInstance.expect([">>", "\r?\n", "{\x08"])
			if what == 0:
				break
			elif what == 2:
				matlabInterface.matlabInstance.expect("}\x08")
				output = matlabInterface.matlabInstance.before.strip().replace("\r", "")
				print >> sys.stderr, output
				errors += output.split("\n")
			else:
				output = matlabInterface.matlabInstance.before.strip()
				if output:
					print output
		if errors:
			el = []
			for i in range(2, len(errors)):
				match = re.search("^Error in (\w+) \(line ([0-9]+)\)", errors[i])
				if match:
					el += [ {
						"filename": match.group(1) + ".m",
						"lnum": int(match.group(2)),
						"text": errors[i-2]
					} ]
					vim.command("call setqflist(" + repr(el) + ")")
					vim.command("cwindow")
					break


	@staticmethod
	def execFile():
		matlabInterface.startup()
		path, fn = os.path.split(vim.current.buffer.name)
		function, ext = os.path.splitext(fn)

		matlabInterface.matlabInstance.send("chdir('{0}');\n{1}\n".format(path, function))
		matlabInterface.matlabInstance.expect(">>")
		matlabInterface.matlabInstance.readline()
		matlabInterface.showOutput()

	@staticmethod
	def command(cmd=None):
		matlabInterface.startup()
		if cmd == None:
			vim.command('let b:matlab_command_input = input(">> ")');
			matlabInterface.matlabInstance.send("{0}\n".format(vim.eval('b:matlab_command_input')));
		else:
			matlabInterface.matlabInstance.send("{0}\n".format(cmd));
		matlabInterface.matlabInstance.readline()
		matlabInterface.showOutput()
	
	@staticmethod
	def checkKill():
		if matlabInterface.matlabInstance != None and matlabInterface.matlabInstance.isalive():
			if not any([ x[-2:] == ".m" for x in vim.buffers ]):
				matlabInterface.matlabInstance.kill(15)
				matlabInterface.matlabInstance = None
END

map <F5> :py matlabInterface.execFile()<CR>
map <S-F5> :py matlabInterface.command()<CR>
au BufWipeout *.m :py matlabInterface.checkKill()<CR>
com! -nargs=1 MatlabDo :py matlabInterface.command('<args>')
