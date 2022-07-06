#!/bin/sh

if [ $1 ]; then
	export ROOTDIR=$1
	export CHROOTDIR=$1
else
	export ROOTDIR=""
	export CHROOTDIR="/"
fi

if [[ -f $ROOTDIR/usr/lib64/libc.so ]]; then
	BASELIB='lib64'
else
	BASELIB='lib'
fi

function _cleanup_utils() {
	CONTAINER=$1
	buildah run $CONTAINER -- rm /bin/chmod
	buildah run $CONTAINER -- rm /bin/mkdir
	buildah run $CONTAINER -- rm /bin/ls
	buildah run $CONTAINER -- rm /bin/ln
	buildah run $CONTAINER -- rm /bin/sh
	buildah run $CONTAINER -- rm /bin/chown
	buildah run $CONTAINER -- rm /usr/sbin/useradd
	buildah run $CONTAINER -- rm /usr/sbin/groupadd
	buildah run $CONTAINER -- rm /bin/rm
}

function _copy_ldd() {
	CONTAINER=$1
	BINFILE=$2

	SAVEIFS=$IFS
	IFS=$'\n'
	ARR=(`chroot $CHROOTDIR ldd -- $BINFILE`)
	IFS=$SAVEIFS
	for (( i=0; i<${#ARR[@]}; i++ ))
	do
    	LIBFILE=$(echo "${ARR[$i]}"|awk '{print $3}')
		if [ "$LIBFILE" != "" ] && [ "$LIBFILE" != "ldd" ]; then
			buildah copy $CONTAINER "$ROOTDIR/$LIBFILE" $LIBFILE
		fi
	done
}

function _print_header() {
	echo "#####################################################"
	echo "##################### $1 ############################"
	echo "#####################################################"
}

function microgentoo_base() {
	_print_header "base"
	CONTAINER=$(buildah from scratch)

	export CHOST=$(chroot $CHROOTDIR emerge -- --info |grep CHOST|sed 's/CHOST="//g'|sed 's/"//g')

	buildah copy $CONTAINER $ROOTDIR/bin/mkdir /bin/
	buildah copy $CONTAINER $ROOTDIR/bin/chmod /bin/
	buildah copy $CONTAINER $ROOTDIR/bin/ls /bin/
	buildah copy $CONTAINER $ROOTDIR/bin/ln /bin/
	buildah copy $CONTAINER $ROOTDIR/bin/rm /bin/
	buildah copy $CONTAINER $ROOTDIR/bin/sh /bin/
	buildah copy $CONTAINER $ROOTDIR/bin/chown /bin/
	buildah copy $CONTAINER $ROOTDIR/usr/sbin/useradd /usr/sbin/
	buildah copy $CONTAINER $ROOTDIR/usr/sbin/groupadd /usr/sbin/

	# etc
	buildah copy $CONTAINER passwd /etc/
	buildah copy $CONTAINER group /etc/
	buildah copy $CONTAINER $ROOTDIR/etc/ld.so.conf /etc/
	buildah copy $CONTAINER $ROOTDIR/etc/ssl/ /etc/ssl/
	buildah copy $CONTAINER $ROOTDIR/etc/env.d/ /etc/env.d/
	buildah copy $CONTAINER $ROOTDIR/etc/environment.d/ /etc/environment.d/
	buildah copy $CONTAINER $ROOTDIR/etc/ca-certificates.conf /etc/
	buildah copy $CONTAINER $ROOTDIR/etc/services /etc/
	buildah copy $CONTAINER $ROOTDIR/etc/protocols /etc/
	buildah copy $CONTAINER $ROOTDIR/etc/mime.types /etc/
	buildah copy $CONTAINER $ROOTDIR/etc/os-release /etc/
	buildah copy $CONTAINER $ROOTDIR/etc/DIR_COLORS /etc/
	buildah copy $CONTAINER $ROOTDIR/etc/profile /etc/
	buildah copy $CONTAINER $ROOTDIR/etc/profile.env /etc/

	if [ "${CHOST}" == "x86_64-gentoo-linux-musl" ]; then
		export CHOSTBASE="musl"
		buildah copy $CONTAINER $ROOTDIR/usr/${BASELIB}/libc.so /usr/${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/ld-musl-x86_64.so.1 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/etc/ld-musl-x86_64.path /etc/
	else
		export CHOSTBASE="gnu"
		buildah copy $CONTAINER $ROOTDIR/etc/nsswitch.conf /etc/
		buildah copy $CONTAINER $ROOTDIR/etc/ld.so.cache /etc/
		buildah copy $CONTAINER $ROOTDIR/etc/ld.so.conf.d/ /etc/ld.so.conf.d/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libc.so.6 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/ld-linux-x86-64.so.2 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libm.so.6 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libdl.so.2 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libutil.so.1 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libnss_compat.so.2 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libnss_db.so.2 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libnss_dns.so.2 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libnss_files.so.2 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libresolv.so.2 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libpthread.so.0 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/librt.so.1 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libcrypt.so.1 /${BASELIB}/
		buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libcrypt.so.2 /${BASELIB}/
	fi

	buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libacl.so.1 /${BASELIB}/
	buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libattr.so.1 /${BASELIB}/
	buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libtinfo.so.6 /${BASELIB}/
	buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libtinfow.so.6 /${BASELIB}/
	buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libz.so.1 /${BASELIB}/
	buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libbz2.so.1 /${BASELIB}/
	buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libreadline.so.8 /${BASELIB}/
	buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libtinfo.so.6 /${BASELIB}/
	buildah copy $CONTAINER $ROOTDIR/${BASELIB}/libtinfow.so.6 /${BASELIB}/

	# usr
	buildah copy $CONTAINER $ROOTDIR/usr/${BASELIB}/libcrypto.so.1.1 /usr/${BASELIB}/
	buildah copy $CONTAINER $ROOTDIR/usr/${BASELIB}/libssl.so.1.1 /usr/${BASELIB}/
	buildah copy $CONTAINER $ROOTDIR/usr/${BASELIB}/libffi.so.8 /usr/${BASELIB}/
	buildah copy $CONTAINER $ROOTDIR/usr/${BASELIB}/libexpat.so.1 /usr/${BASELIB}/

	buildah run $CONTAINER -- /bin/ln -s /usr/${BASELIB}/libcrypto.so.1.1 /usr/${BASELIB}/libcrypto.so
	buildah run $CONTAINER -- /bin/ln -s /usr/${BASELIB}/libcrypto.so.1.1 /usr/${BASELIB}/libcrypto.so.1
	buildah run $CONTAINER -- /bin/ln -s /usr/${BASELIB}/libssl.so.1.1 /usr/${BASELIB}/libssl.so

	# other
	buildah copy $CONTAINER $ROOTDIR/usr/share/ca-certificates/ /usr/share/ca-certificates/
	buildah run $CONTAINER -- mkdir /{root,var,tmp,var/empty,sbin,/usr/bin}
	buildah run $CONTAINER -- chmod 777 /tmp

	buildah commit $CONTAINER microgentoo/$CHOSTBASE/base:latest
	buildah rm $CONTAINER
}

push_images(){
	buildah push ${REGISTRY_ARGS} microgentoo/$CHOSTBASE/base:latest ${REGISTRY_URL}/microgentoo/$CHOSTBASE/base:latest
	buildah push ${REGISTRY_ARGS} microgentoo/$CHOSTBASE/gcc:latest ${REGISTRY_URL}/microgentoo/$CHOSTBASE/gcc:latest
	buildah push ${REGISTRY_ARGS} microgentoo/$CHOSTBASE/python:latest ${REGISTRY_URL}/microgentoo/$CHOSTBASE/python:latest
	buildah push ${REGISTRY_ARGS} microgentoo/$CHOSTBASE/nodejs:latest ${REGISTRY_URL}/microgentoo/$CHOSTBASE/nodejs:latest
	buildah push ${REGISTRY_ARGS} microgentoo/$CHOSTBASE/zeromq:latest ${REGISTRY_URL}/microgentoo/$CHOSTBASE/zeromq:latest
	buildah push ${REGISTRY_ARGS} microgentoo/$CHOSTBASE/packer:latest ${REGISTRY_URL}/microgentoo/$CHOSTBASE/packer:latest
	buildah push ${REGISTRY_ARGS} microgentoo/$CHOSTBASE/openssh:latest ${REGISTRY_URL}/microgentoo/$CHOSTBASE/openssh:latest
	buildah push ${REGISTRY_ARGS} microgentoo/$CHOSTBASE/git:latest ${REGISTRY_URL}/microgentoo/$CHOSTBASE/git:latest
	buildah push ${REGISTRY_ARGS} microgentoo/$CHOSTBASE/openjdk:latest ${REGISTRY_URL}/microgentoo/$CHOSTBASE/openjdk:latest
	buildah push ${REGISTRY_ARGS} microgentoo/$CHOSTBASE/ruby:latest ${REGISTRY_URL}/microgentoo/$CHOSTBASE/ruby:latest
	buildah push ${REGISTRY_ARGS} microgentoo/$CHOSTBASE/php:latest ${REGISTRY_URL}/microgentoo/$CHOSTBASE/php:latest
}

microgentoo_base

if [ $2 ]; then
	source src/$2
	microgentoo_$2
else
	arr=$(cat packages)
	for f in ${arr[@]}; do
    	source src/$f
		microgentoo_$f
	done
fi

