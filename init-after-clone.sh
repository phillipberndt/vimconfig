#!/bin/sh
#
git submodule init
git submodule update
git submodule foreach git checkout master
python update-scripts.py
if ! -e vim-personal; then
	echo "Enter your personal data:"
	for FIELD in $(cut -d= -f1 vim-personal.template); do
		echo -ne "$FIELD:\033[15G"
		read VALUE
		echo "$FIELD=$VALUE" >> vim-personal
	done
fi
