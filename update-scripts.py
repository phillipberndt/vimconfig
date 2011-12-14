#!/usr/bin/python
import os
import urllib
import re
import urlparse
working_directory = os.getcwd()
for root, dirs, files in os.walk("."):
	os.chdir(root)
	if ".bzr" in dirs:
		print "\033[1mUpdating", root, "with bzr\033[0m"
		os.system("bzr up")
	if ".git" in dirs:
		print "\033[1mUpdating", root, "with git\033[0m"
		os.system("git pull")
	elif "source" in files:
		# Source file syntax:
		# Three lines. The first line determines a mode: search or download.
		# search mode: URL to a page in the second line, regular expression to get the download link
		# in the third line. Should point to an archive which the script then downloads & unpacks 
		# Optional fourth line means "don't unpack but place into this location"
		# download mode: Second line points to a url, third to a filename to store this file in
		print "\033[1mUpdating ", root, "manually\033[0m"
		package_info = [ x.strip() for x in open("source").readlines() ]
		if len(package_info) == 3:
			package_info.append(False)
		mode, url, pattern, optional = package_info
		if mode == "search":
			html_page = urllib.urlopen(url).read()
			found_download_url = re.search(pattern, html_page).group(0)
			download_url = urlparse.urljoin(url, found_download_url)
			if optional:
				directory = os.path.dirname(optional)
				if not os.path.exists(directory):
					os.makedirs(directory)
				urllib.urlretrieve(download_url, optional)
			else:
				urllib.urlretrieve(download_url, "package.archive")
				archive_inner_type = os.popen("file --uncompress --brief --mime-type package.archive").read().strip()
				archive_container_type = os.popen("file --brief --mime-type package.archive").read().strip()
				if archive_inner_type == "application/x-tar" and archive_container_type == "application/x-gzip":
					os.system("tar xzf package.archive && rm package.archive")
				elif archive_inner_type == "application/x-tar" and archive_container_type == "application/x-bzip2":
					os.system("tar xjf package.archive && rm package.archive")
				elif archive_container_type == "application/zip":
					os.system("unzip -o package.archive && rm package.archive")
				else:
					print "Unable to extract archive of type", archive_container_type, "containing", archive_inner_type
		elif mode == "download":
			directory = os.path.dirname(pattern)
			if not os.path.exists(directory):
				os.makedirs(directory)
			urllib.urlretrieve(url, pattern)
	os.chdir(working_directory)
