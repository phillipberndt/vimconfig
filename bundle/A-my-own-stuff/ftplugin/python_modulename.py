#!/usr/bin/env python
import os
import pkgutil
import re
import sys

def find_module(module, paths=None):
	if "." in module:
		module, subs = module.split(".", 1)
	else:
		subs = False
	if not paths:
		paths = sys.path
	for path in paths:
		mod = os.path.join(path, module + ".py")
		path = os.path.join(path, module)
		init = os.path.join(path, "__init__.py")
		if os.path.isdir(path) and os.access(init, os.R_OK):
			if subs:
				path = find_module(subs, (path,))
				if path:
					return path
			else:
				return path
		elif os.access(mod, os.R_OK):
			return mod
	return False

arg = sys.argv[1]

lib = re.search("(?i)from\s+(\S+)\s+import\s+([^, \t]+)", arg)
if lib:
	imp = lib.group(1) + "." + lib.group(2)
	file = find_module(imp)
	if not file:
		imp = lib.group(1)
		file = find_module(imp)
else:
	lib = re.search("(?i)import\s+(\S+)")
	if lib:
		imp = lib.group(1)
		file = find_module(imp)

if file:
	print file
