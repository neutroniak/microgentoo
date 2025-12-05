#!/bin/sh

if [ $1 ]; then
	source /etc/microgentoo/$1
else
	echo "No config file found.. Exiting"
	echo "Usage: ./build <config>"
	exit 1
fi

export PACKAGES
export ROOTDIR
export PREFIX

if [ "x$ROOTDIR" == "x/" ]; then
	export ROOTDIR=""
	export CHROOTDIR="/"
else
	export ROOTDIR=$ROOTDIR
	export CHROOTDIR=$ROOTDIR
fi

if [[ -f $ROOTDIR/usr/lib64/libc.so ]]; then
	BASELIB='lib64'
else
	BASELIB='lib'
fi

export BASELIB

source include/functions

source src/base

microgentoo_base

arr=$PACKAGES
for f in ${arr[@]}; do
   	source src/$f
	microgentoo_$f
done

