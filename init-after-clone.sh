#!/bin/bash
#
git submodule init
git submodule update
git submodule foreach git checkout master
find bundle -name .gitmodules -printf "%h\n" | while read DIR; do
	(
		cd $DIR
		if [ -f .gitmodules ]; then
			git submodule init
			git submodule update
		fi
	)
done
git submodule foreach --recursive git checkout master

python update-scripts.py
if ! -e vim-personal; then
	echo "Enter your personal data:"
	for FIELD in $(cut -d= -f1 vim-personal.template); do
		echo -ne "$FIELD:\033[15G"
		read VALUE
		echo "$FIELD=$VALUE" >> vim-personal
	done
fi

if ! vim --version | grep -q "+python"; then
	echo
	echo "You have a VIM version without python support installed."
	echo "I will now remove everything incompatible:"
	cd bundle
	for dir in *; do
		if [ -d $dir/.git ]; then
			if grep -Rq ":py " $dir; then
				rm -rf $dir
				echo $dir
			fi
		else
			grep -Rl ":py " | while read name; do
				echo $name
				rm -f $name
			done
		fi
	done
	cd ..
fi
