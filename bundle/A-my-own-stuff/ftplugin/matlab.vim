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
import time
import os
class matlabInterface:
	matlabInstance = None
	lockOutput = False
	commandActive = False
	bufferWindow = None
	errors = []

	@staticmethod
	def startup():
		if matlabInterface.matlabInstance == None or not matlabInterface.matlabInstance.isalive():
			print "Starting MATLAB.."
			matlabInterface.matlabInstance = pexpect.spawn("matlab -nodesktop -nosplash")
			matlabInterface.matlabInstance.expect(">>")
	
	@staticmethod
	def showOutput():
		matlabInterface.commandActive = True
		if matlabInterface.lockOutput == True:
			return
		matlabInterface.lockOutput = True
		vim.command("split")
		vim.command("wincmd j")
		vim.command("setlocal noswapfile")
		vim.command("enew!")
		vim.command("setlocal buftype=nofile")
		vim.command("setlocal nonumber")
		vim.command("au BufHidden <buffer> :py matlabInterface.sendInt()")
		vim.command("map <buffer> <ESC> :close \| :py matlabInterface.sendInt()<CR>")
		vim.command("setlocal updatetime=500")
		vim.command("au CursorHold,CursorMoved <buffer> :py matlabInterface.refresh()")
		vim.command("res 10")

	@staticmethod
	def sendInt():
		matlabInterface.lockOutput = False
		try:
			if matlabInterface.commandActive == True:
				print "Aborting command!"
				matlabInterface.matlabInstance.kill(2)
				matlabInterface.commandActive = False
				matlabInterface.matlabInstance.expect(">>")
		except:
			pass
	
	@staticmethod
	def showErrors():
		errors = matlabInterface.errors[:]
		matlabInterface.errors = []
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
	def refresh():
		if matlabInterface.matlabInstance and matlabInterface.matlabInstance.isalive() and matlabInterface.lockOutput and matlabInterface.commandActive:
			while True:
				try:
					what = matlabInterface.matlabInstance.expect([">>", "\r?\n", "{\x08", pexpect.TIMEOUT], 0)
				except:
					matlabInterface.lockOutput = False
					matlabInterface.commandActive = False
					print >> sys.stderr, "Matlab failed unexpectedly. Remaining output was:\n" + matlabInterface.matlabInstance.before
					matlabInterface.showErrors()
					return
				if what == 0:
					matlabInterface.commandActive = False
					vim.current.buffer.append(">> ")
					vim.command("normal G")
					matlabInterface.showErrors()
				elif what == 1:
					output = matlabInterface.matlabInstance.before.replace("\r", " ").replace("\n", " ")
					if output:
						vim.current.buffer.append(output)
						vim.command("normal G")
				elif what == 2:
					matlabInterface.matlabInstance.expect("}\x08")
					output = matlabInterface.matlabInstance.before.strip().replace("\r", "")
					#print >> sys.stderr, output
					matlabInterface.errors += output.split("\n")
					for l in output.split("\n"):
						vim.current.buffer.append(l)
				elif what == 3:
					bef = matlabInterface.matlabInstance.before.strip()
					if bef != "":
						vim.command("normal G")
						if bef[:len(vim.current.line)] != vim.current.line:
							vim.current.buffer.append("")
						vim.current.line = bef
					vim.command("normal Gkj")
					return
			vim.command("normal Gkj")

	@staticmethod
	def execFile():
		if matlabInterface.commandActive == True:
			print >> sys.stderr, "Can not exec file while other command is active."
			return
		matlabInterface.startup()
		path, fn = os.path.split(vim.current.buffer.name)
		function, ext = os.path.splitext(fn)

		matlabInterface.matlabInstance.send("chdir('{0}');\n{1}\n".format(path, function))
		matlabInterface.matlabInstance.expect(">>")
		matlabInterface.matlabInstance.readline()
		matlabInterface.commandActive = True
		matlabInterface.showOutput()

	@staticmethod
	def command(cmd=None):
		if cmd == None:
			vim.command('let b:matlab_command_input = input(">> ")');
			cmd = vim.eval('b:matlab_command_input')
		matlabInterface.startup()
		matlabInterface.matlabInstance.send("{0}\n".format(cmd));
		matlabInterface.commandActive = True
		if matlabInterface.lockOutput == True:
			return
		matlabInterface.matlabInstance.readline()
		matlabInterface.showOutput()
	
	@staticmethod
	def checkKill():
		if matlabInterface.matlabInstance != None and matlabInterface.matlabInstance.isalive():
			if not any([ x[-2:] == ".m" for x in vim.buffers ]):
				matlabInterface.matlabInstance.kill(15)
				matlabInterface.matlabInstance = None
				matlabInterface.lockOutput = False
				matlabInterface.commandActive = False
END

map <F5> :py matlabInterface.execFile()<CR>
map <S-F5> :py matlabInterface.command()<CR>
au BufWipeout *.m :py matlabInterface.checkKill()<CR>
com! -nargs=1 MatlabDo :py matlabInterface.command('<args>')
