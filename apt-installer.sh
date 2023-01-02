#!/bin/bash

# abort script on any error
set -e


# function: Checks two string arguments for not being comments
# 	$1: any string
# 	$2: any string
function shouldExecute
{
	if [[ $1 =~ ^[^#] ]] && [[ $2 =~ ^[^#] ]];
	then
		return 0
	else
		return 1
	fi
}


# function: Downloads a file to the current working directory
# 	$1: source directory
# 	$2: file name
function download
{
	if ! [ -f "$2" ]; then
		echo -e "\e[0;33m-- $2 --\e[0m"
		wget $1$2;
	fi
}


# function: Installs a package file to debian OS on PLCnext device
# 	$1: source package name
function install
{
	echo -e "\e[0;33m-- $1 --\e[0m"

	if [[ $1 =~ ^passwd[^a-zA-Z0-9] ]] && [ $(grep -c '^shadow:x:' '/etc/group') -eq 1 ]; then
		# delete the 'shadow' group as the 'passwd' package will re-create this group
		groupdel shadow
		echo -e "\e[0;30mShadow group deleted. Will be re-created by 'passwd' package.\e[0m"
	fi

	if [[ $1 =~ ^libc6[^a-zA-Z0-9] ]]; then
		echo -e "\e[0;30mSkipping dependency check and configuration due to circular reference.\e[0m"
		dpkg -i --force-confdef,confnew,depends $1;
	else
		dpkg -i --force-confdef,confnew $1;
		dpkg --configure -a
	fi
}



# set variables
scriptDir=$(realpath $(dirname "${BASH_SOURCE[0]}"))
pkgFileName='packages.txt'
pkgFilePath="$scriptDir/$pkgFileName"
downloadDir="$scriptDir/download"

# read optional command line parameters
#		$1 path and name of file containing the list of packages
if [ -n "$1" ]; then
	pkgFilePath=$(dirname $1)
	pkgFileName=$(basename $1)
fi

# check if file containing the list of packages does exist
if ! [ -f "$pkgFilePath" ]; then
	echo -e '\n\e[0;31mPackage file for downloading packages could not be found.\e[0m'
	echo -e "Please create \"$pkgFileName\" file in \"$pkgFilePath\", with lines containing directory path and file name, separated by whitespace, for every package to download.\n"
	exit 1
fi

# unset failure delay time
sed -i -e 's/^\s*FAIL_DELAY/#FAIL_DELAY/' /etc/login.defs

# create download directory
[ -d "$downloadDir" ] || mkdir $downloadDir

# go to download directory
pushd $scriptDir
cd $downloadDir


# download all packages. If a package cannot be downloaded, the script will abort and fail
echo -e '\n\e[0;32mDownloading files ...\e[0m'
while read -ra tokens; do shouldExecute "${tokens[0]}" "${tokens[1]}" && download ${tokens[0]} ${tokens[1]}; done < $pkgFilePath

# install the downloaded packages
echo -e '\n\e[0;32mInstalling files ...\e[0m'
while read -ra tokens; do shouldExecute "${tokens[0]}" "${tokens[1]}" && install ${tokens[1]}; done < $pkgFilePath


# restore working directory
popd >/dev/null

# delete downloaded packages and remove download directory to save space
rm -rf $downloadDir

# reset failure delay time
sed -i -e 's/^\s*#FAIL_DELAY/FAIL_DELAY/' /etc/login.defs


# add apt repositories
echo -e '\n\e[0;32mRegistering apt repositories ...\e[0m'
echo "deb [trusted=yes] http://deb.debian.org/debian bullseye main contrib non-free
deb-src [trusted=yes] http://deb.debian.org/debian bullseye main contrib non-free

deb [trusted=yes] http://deb.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src [trusted=yes] http://deb.debian.org/debian-security/ bullseye-security main contrib non-free

deb [trusted=yes] http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src [trusted=yes] http://deb.debian.org/debian bullseye-updates main contrib non-free" > /etc/apt/sources.list

#update the package lists in the PLCnext device
echo -e '\n\e[0;32mUpdating apt packages ...\e[0m'
apt update

# show the available disk space on PLCnext device
echo -e '\n\e[0;32mFree disk space:\e[0m'
df -h

echo
exit 0