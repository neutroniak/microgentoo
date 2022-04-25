#!/bin/sh

if [[ -f /usr/lib64/libc.so ]]; then
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
	ARR=(`ldd $BINFILE`)
	IFS=$SAVEIFS
	for (( i=0; i<${#ARR[@]}; i++ ))
	do
    	LIBFILE=$(echo "${ARR[$i]}"|awk '{print $3}')
		if [ "$LIBFILE" != "" ] && [ "$LIBFILE" != "ldd" ]; then
			buildah copy $CONTAINER $LIBFILE $LIBFILE
		fi
	done
}

function _print_header() {
	echo "#####################################################"
	echo "##################### $1 ############################"
	echo "#####################################################"
}

function gentoo_container_base() {
	_print_header "base"
	CONTAINER=$(buildah from scratch)

	export CHOST=$(emerge --info |grep CHOST|sed 's/CHOST="//g'|sed 's/"//g')

	buildah copy $CONTAINER /bin/mkdir /bin/
	buildah copy $CONTAINER /bin/chmod /bin/
	buildah copy $CONTAINER /bin/ls /bin/
	buildah copy $CONTAINER /bin/ln /bin/
	buildah copy $CONTAINER /bin/rm /bin/
	buildah copy $CONTAINER /bin/sh /bin/
	buildah copy $CONTAINER /bin/chown /bin/
	buildah copy $CONTAINER /usr/sbin/useradd /usr/sbin/
	buildah copy $CONTAINER /usr/sbin/groupadd /usr/sbin/

	# etc
	buildah copy $CONTAINER /etc/ld.so.conf /etc/
	buildah copy $CONTAINER /etc/ssl/* /etc/ssl/
	buildah copy $CONTAINER /etc/env.d/* /etc/env.d/
	buildah copy $CONTAINER /etc/environment.d/* /etc/environment.d/
	buildah copy $CONTAINER /etc/ca-certificates.conf /etc/
	buildah copy $CONTAINER /etc/services /etc/
	buildah copy $CONTAINER /etc/protocols /etc/
	buildah copy $CONTAINER /etc/mime.types /etc/
	buildah copy $CONTAINER /etc/os-release /etc/
	buildah copy $CONTAINER /etc/DIR_COLORS /etc/
	buildah copy $CONTAINER /etc/profile /etc/
	buildah copy $CONTAINER /etc/profile.env /etc/

	if [ "${CHOST}" == "x86_64-gentoo-linux-musl" ]; then
		
		buildah copy $CONTAINER /usr/${BASELIB}/libc.so /usr/${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/ld-musl-x86_64.so.1 /${BASELIB}/
		buildah copy $CONTAINER /etc/ld-musl-x86_64.path /etc/
	else
		buildah copy $CONTAINER /etc/nsswitch.conf /etc/
		buildah copy $CONTAINER /etc/ld.so.cache /etc/
		buildah copy $CONTAINER /etc/ld.so.conf.d/* /etc/ld.so.conf.d/
		buildah copy $CONTAINER /${BASELIB}/libc.so.6 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/ld-linux-x86-64.so.2 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/libm.so.6 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/libdl.so.2 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/libutil.so.1 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/libnss_compat.so.2 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/libnss_db.so.2 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/libnss_dns.so.2 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/libnss_files.so.2 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/libresolv.so.2 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/libpthread.so.0 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/librt.so.1 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/libcrypt.so.1 /${BASELIB}/
		buildah copy $CONTAINER /${BASELIB}/libcrypt.so.2 /${BASELIB}/
	fi

	buildah copy $CONTAINER /${BASELIB}/libacl.so.1 /${BASELIB}/
	buildah copy $CONTAINER /${BASELIB}/libattr.so.1 /${BASELIB}/
	buildah copy $CONTAINER /${BASELIB}/libtinfo.so.6 /${BASELIB}/
	buildah copy $CONTAINER /${BASELIB}/libtinfow.so.6 /${BASELIB}/
	buildah copy $CONTAINER /${BASELIB}/libz.so.1 /${BASELIB}/
	buildah copy $CONTAINER /${BASELIB}/libbz2.so.1 /${BASELIB}/
	buildah copy $CONTAINER /${BASELIB}/libreadline.so.8 /${BASELIB}/
	buildah copy $CONTAINER /${BASELIB}/libtinfo.so.6 /${BASELIB}/
	buildah copy $CONTAINER /${BASELIB}/libtinfow.so.6 /${BASELIB}/

	# usr
	buildah copy $CONTAINER /usr/${BASELIB}/libcrypto.so.1.1 /usr/${BASELIB}/
	buildah copy $CONTAINER /usr/${BASELIB}/libssl.so.1.1 /usr/${BASELIB}/

	buildah run $CONTAINER -- /bin/ln -s /usr/${BASELIB}/libcrypto.so.1.1 /usr/${BASELIB}/libcrypto.so
	buildah run $CONTAINER -- /bin/ln -s /usr/${BASELIB}/libcrypto.so.1.1 /usr/${BASELIB}/libcrypto.so.1
	buildah run $CONTAINER -- /bin/ln -s /usr/${BASELIB}/libssl.so.1.1 /usr/${BASELIB}/libssl.so

	# other
	buildah copy $CONTAINER /usr/share/ca-certificates/* /usr/share/ca-certificates/
	buildah run $CONTAINER -- mkdir /{var,tmp,var/empty,sbin,/usr/bin}
	buildah run $CONTAINER -- chmod 777 /tmp

	buildah commit $CONTAINER gentoo-container-base:latest
	buildah rm $CONTAINER
}

############# python ################
gentoo_container_python() {
	
	_print_header "python"
	
	CONTAINER=$(buildah from gentoo-container-base)

	export PYTHON_VERSION=$(python -V|awk '{print $2}'|awk -F"." '{print $1"."$2}')
	export PYTHON_VERSION_LABEL=$(python -V|awk '{print $2}'|awk -F"." '{print $1"."$2.".y"}')
	buildah copy --ignorefile .containerignore --contextdir /usr/ $CONTAINER /usr/lib/python${PYTHON_VERSION}/ /usr/lib/python${PYTHON_VERSION}/
	buildah copy $CONTAINER /usr/lib/python-exec/python${PYTHON_VERSION}/* /usr/lib/python-exec/python${PYTHON_VERSION}/
	buildah copy $CONTAINER /usr/${BASELIB}/libpython${PYTHON_VERSION}.so.1.0 /usr/${BASELIB}/
	buildah copy $CONTAINER /usr/bin/python${PYTHON_VERSION} /usr/bin/
	buildah copy $CONTAINER /usr/bin/python-exec2c /usr/bin/
	buildah copy $CONTAINER /usr/bin/python${PYTHON_VERSION}-config /usr/bin/
	buildah copy $CONTAINER /usr/lib/python-exec/python-exec2 /usr/lib/python-exec/
	buildah copy $CONTAINER /etc/python-exec/* /etc/python-exec/
	
	buildah copy $CONTAINER /usr/${BASELIB}/libexpat.so.1 /usr/${BASELIB}/
	buildah copy $CONTAINER /usr/${BASELIB}/libffi.so.7 /usr/${BASELIB}/
	
	buildah run $CONTAINER -- sh -c 'cd /usr/bin && ln -s python-exec2c python'
	buildah run $CONTAINER -- sh -c 'cd /usr/bin && ln -s python-exec2c python3'
	buildah run $CONTAINER -- sh -c 'cd /usr/bin && ln -s ../lib/python-exec/python-exec2 pip'
	buildah run $CONTAINER -- sh -c 'cd /usr/bin && ln -s ../lib/python-exec/python-exec2 pip3'
	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s ../lib/python-exec/python-exec2 pip${PYTHON_VERSION}"
	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s ../lib/python-exec/python-exec2 pyenv"
	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s ../lib/python-exec/python-exec2 python3-config"

	# clean and commit
	_cleanup_utils $CONTAINER
	buildah commit $CONTAINER gentoo-container-python:${PYTHON_VERSION_LABEL}
	buildah rm $CONTAINER
}

############# openssh client ########
gentoo_container_openssh_client() {

	_print_header "openssh client"

	CONTAINER=$(buildah from gentoo-container-base)

	export SSH_VERSION=$(ssh -V 2>/dev/stdout|awk '{print $1}'|sed 's/OpenSSH_//g'|sed 's/,//g')

	buildah copy $CONTAINER  /etc/ssh/moduli /etc/ssh/
	buildah copy $CONTAINER /etc/ssh/ssh_config /etc/ssh/

	buildah copy $CONTAINER /usr/bin/ssh /usr/bin/
	buildah copy $CONTAINER /usr/bin/scp /usr/bin/
	buildah copy $CONTAINER /usr/bin/sftp /usr/bin/

	# clean and commit
	_cleanup_utils $CONTAINER
	buildah commit $CONTAINER gentoo-container-openssh-client:${SSH_VERSION}
	buildah rm $CONTAINER
}

############# nginx #################
gentoo_container_nginx() {

	_print_header "nginx"

	CONTAINER=$(buildah from gentoo-container-base)

	export NGINX_VERSION=$(nginx -v 2>/dev/stdout|line 1|awk -F '/' '{print $2}'|awk -F "." '{print $1"."$2.".y"}')

	buildah copy $CONTAINER /${BASELIB}/libpcre.so.1 /${BASELIB}/
	buildah copy $CONTAINER /usr/sbin/nginx /usr/sbin/
	buildah copy $CONTAINER /etc/nginx/ /etc/nginx/
	buildah copy $CONTAINER /var/www/ /var/www/

	buildah run $CONTAINER -- mkdir -p /var/log/nginx
	buildah run $CONTAINER -- mkdir -p /var/lib/nginx/tmp

	buildah run $CONTAINER -- groupadd nginx
	buildah run $CONTAINER -- useradd -r -d /var/lib/nginx -G nginx -s /sbin/nologin nginx

	buildah run $CONTAINER -- chown -R nginx:nginx /var/log/nginx
	buildah run $CONTAINER -- chown -R nginx:nginx /var/lib/nginx
	
	# clean and commit
	_cleanup_utils $CONTAINER
	buildah commit $CONTAINER gentoo-container-nginx:${NGINX_VERSION}
	buildah rm $CONTAINER
}

############# git ###################
gentoo_container_git() {

	_print_header "git"

	CONTAINER=$(buildah from gentoo-container-base)

	export GIT_VERSION=$(git --version|awk '{print $3}' |awk -F "." '{print $1"."$2.".y"}' )

	buildah copy $CONTAINER /usr/bin/git-upload-pack /usr/bin/
	buildah copy $CONTAINER /usr/bin/git-upload-archive /usr/bin/
	buildah copy $CONTAINER /usr/bin/git-receive-pack /usr/bin/
	buildah copy $CONTAINER /usr/bin/import-tars /usr/bin/
	buildah copy $CONTAINER /usr/bin/git /usr/bin/ 

	buildah copy $CONTAINER /usr/libexec/git-core/git-verify-tag /usr/libexec/git-core/
	buildah copy $CONTAINER /usr/libexec/git-core/git-verify-pack /usr/libexec/git-core/
	buildah copy $CONTAINER /usr/libexec/git-core/git-verify-commit /usr/libexec/git-core/
	buildah copy $CONTAINER /usr/libexec/git-core/git-var /usr/libexec/git-core/
	buildah copy $CONTAINER /usr/libexec/git-core/git-pull /usr/libexec/git-core/
	buildah copy $CONTAINER /usr/libexec/git-core/git-fetch /usr/libexec/git-core/
	buildah copy $CONTAINER /usr/libexec/git-core/git-clone /usr/libexec/git-core/
	buildah copy $CONTAINER /usr/libexec/git-core/git-checkout /usr/libexec/git-core/
	buildah copy $CONTAINER /usr/libexec/git-core/git-branch /usr/libexec/git-core/
	buildah copy $CONTAINER /usr/libexec/git-core/git /usr/libexec/git-core/
	buildah copy $CONTAINER /usr/libexec/git-core/git-http-fetch /usr/libexec/git-core/

	# clean and commit
	_cleanup_utils $CONTAINER
	buildah commit $CONTAINER gentoo-container-git:${GIT_VERSION}
	buildah rm $CONTAINER
}

############# ruby ##################
gentoo_container_ruby() {

	_print_header "ruby"

	CONTAINER=$(buildah from gentoo-container-base)

	export RUBY_VERSION=$(ruby -v |awk '{print $2}'|awk -F "." '{print $1"."$2}')
	export RUBY_VERSION_NUM=${RUBY_VERSION/\./}
	export RUBY_VERSION_LABEL=$(ruby -v |awk '{print $2}'|awk -F "." '{print $1"."$2.".y"}')
	buildah copy $CONTAINER /usr/bin/bundle /usr/bin/
	buildah copy $CONTAINER /usr/bin/bundler /usr/bin/
	buildah copy $CONTAINER /usr/bin/rake /usr/bin/
	buildah copy $CONTAINER /usr/bin/racc /usr/bin/
	buildah copy $CONTAINER /usr/bin/gem${RUBY_VERSION_NUM} /usr/bin/
	buildah copy $CONTAINER /usr/bin/irb${RUBY_VERSION_NUM} /usr/bin/
	buildah copy $CONTAINER /usr/bin/erb${RUBY_VERSION_NUM} /usr/bin/
	buildah copy $CONTAINER /usr/bin/ruby${RUBY_VERSION_NUM} /usr/bin/

	buildah copy $CONTAINER /usr/${BASELIB}/ruby/ /usr/${BASELIB}/ruby/
	buildah copy $CONTAINER /usr/${BASELIB}/libruby${RUBY_VERSION_NUM}.so.${RUBY_VERSION} /usr/${BASELIB}/

	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s ruby${RUBY_VERSION_NUM} ruby"
	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s irb${RUBY_VERSION_NUM} irb"
	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s gem${RUBY_VERSION_NUM} gem"
	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s erb${RUBY_VERSION_NUM} erb"

	# clean and commit
	_cleanup_utils $CONTAINER
	buildah commit $CONTAINER gentoo-container-ruby:${RUBY_VERSION_LABEL}
	buildah rm $CONTAINER
}

############# nodejs ##################
gentoo_container_nodejs() {

	_print_header "nodejs"

	CONTAINER=$(buildah from gentoo-container-base)

	export NODEJS_VERSION=$(node -v |sed 's/v//g' |awk -F "." '{print $1"."$2.".y"}')

	buildah copy --ignorefile .containerignore --contextdir /usr/ $CONTAINER /usr/${BASELIB}/node_modules/ /usr/${BASELIB}/node_modules/
	buildah copy $CONTAINER /usr/bin/env /usr/bin/
	buildah copy $CONTAINER /usr/bin/node /usr/bin/
	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s ../${BASELIB}/node_modules/npm/bin/npm-cli.js npm"
	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s ../${BASELIB}/node_modules/npx/bin/npm-cli.js npx"

	_copy_ldd $CONTAINER /usr/bin/node

	# clean and commit
	_cleanup_utils $CONTAINER
	buildah commit $CONTAINER gentoo-container-nodejs:${NODEJS_VERSION}
	buildah rm $CONTAINER
}

############# php fpm ##################
gentoo_container_php_fpm() {

	export PHP_VERSION=$(php-fpm -v |awk '/^PHP/ {print $2}'|awk -F "." '{print $1"."$2}')
	export PHP_VERSION_LABEL=$(php-fpm -v |awk '/^PHP/ {print $2}'|awk -F "." '{print $1"."$2.".y"}')

	_print_header "php fpm $PHP_VERSION_LABEL"

	CONTAINER=$(buildah from gentoo-container-base)

	buildah copy $CONTAINER /etc/php/fpm-php${PHP_VERSION}/ /etc/php/fpm-php${PHP_VERSION}/
	buildah run $CONTAINER -- sh -c "/bin/ln -s /etc/php/fpm-php${PHP_VERSION} /etc/php/fpm-php"

	buildah copy $CONTAINER /usr/${BASELIB}/php${PHP_VERSION}/bin/php-fpm /usr/${BASELIB}/php${PHP_VERSION}/bin/ 
	buildah copy $CONTAINER /usr/${BASELIB}/php${PHP_VERSION}/bin/phar.phar /usr/${BASELIB}/php${PHP_VERSION}/bin/ 
	buildah copy $CONTAINER /usr/${BASELIB}/php${PHP_VERSION}/bin/php-config /usr/${BASELIB}/php${PHP_VERSION}/bin/
	buildah copy $CONTAINER /usr/${BASELIB}/php${PHP_VERSION}/bin/phpize /usr/${BASELIB}/php${PHP_VERSION}/bin/

	buildah copy $CONTAINER /usr/${BASELIB}/php${PHP_VERSION}/${BASELIB}/* /usr/${BASELIB}/php${PHP_VERSION}/${BASELIB}/

	buildah run $CONTAINER -- ln -s /usr/${BASELIB}/php${PHP_VERSION}/bin/phar.phar /usr/${BASELIB}/php${PHP_VERSION}/bin/phar

	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s ../${BASELIB}/php${PHP_VERSION}/bin/php-fpm php-fpm"
	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s ../${BASELIB}/php${PHP_VERSION}/bin/php-config php-config"
	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s ../${BASELIB}/php${PHP_VERSION}/bin/phpize phpize"
	buildah run $CONTAINER -- sh -c "cd /usr/bin && ln -s ../${BASELIB}/php${PHP_VERSION}/bin/phar.phar phar"

	_copy_ldd $CONTAINER /usr/bin/php-fpm

	# clean and commit
	_cleanup_utils $CONTAINER
	buildah commit $CONTAINER gentoo-container-php-fpm:${PHP_VERSION_LABEL}
	buildah rm $CONTAINER
}

############# ruby ##################
gentoo_container_zeromq() {

	_print_header "zeromq"
	
	CONTAINER=$(buildah from gentoo-container-base)

	export ZEROMQ_VERSION_LABEL=$(equery list "*zeromq*"|line 2 |awk -F '/' '{print $2}'|sed 's/zeromq-//g'|awk -F "." '{print $1"."$2.".y"}')

	buildah copy $CONTAINER /usr/${BASELIB}/libzmq.so.5 /usr/${BASELIB}/

	_copy_ldd $CONTAINER /usr/${BASELIB}/libzmq.so.5

	# clean and commit
	_cleanup_utils $CONTAINER
	buildah commit $CONTAINER gentoo-container-zeromq:${ZEROMQ_VERSION_LABEL}
	buildah rm $CONTAINER
}

############# ruby ##################
gentoo_container_packer() {
	CONTAINER=$(buildah from gentoo-container-base)

	export PACKER_VERSION_LABEL=$(packer version|sed 's/Packer v//g' | line 1|awk -F "." '{print $1"."$2.".y"}')

	buildah copy $CONTAINER /usr/bin/packer /usr/bin/

	# clean and commit
	_cleanup_utils $CONTAINER
	buildah commit $CONTAINER gentoo-container-packer:${PACKER_VERSION_LABEL}
	buildah rm $CONTAINER
}

############# busybox ##################
gentoo_container_busybox() {

	_print_header "busybox"

	CONTAINER=$(buildah from gentoo-container-base)

	export BUSYBOX_VERSION_LABEL=$(equery list "*busybox*"|line 2 |awk -F '/' '{print $2}'|sed 's/busybox-//g'|awk -F "." '{print $1"."$2".y"}')

	buildah copy $CONTAINER /bin/busybox /bin/
	buildah copy $CONTAINER busybox.sh /

	_copy_ldd $CONTAINER /bin/busybox

	# clean, make symlinks and commit
	_cleanup_utils $CONTAINER
	buildah run $CONTAINER -- /bin/busybox sh /busybox.sh
	buildah run $CONTAINER -- rm /busybox.sh
	
	buildah commit $CONTAINER gentoo-container-busybox:${BUSYBOX_VERSION_LABEL}
	buildah rm $CONTAINER
}

############# openjdk ###############
gentoo_container_openjdk() {
	CONTAINER=$(buildah from gentoo-container-base)

	export OPENJDK_SLOT_VERSION=$(equery list "*openjdk*"|line 2 |awk -F '/' '{print $2}'|sed 's/openjdk-//g'|awk -F "." '{print $1}')
	export OPENJDK_VERSION_LABEL=$(equery list "*openjdk*"|line 2 |awk -F '/' '{print $2}'|sed 's/openjdk-//g'|awk -F "." '{print $1"."$2".y"}')

	buildah copy $CONTAINER /usr/${BASELIB}/openjdk-${OPENJDK_SLOT_VERSION}/ /usr/${BASELIB}/openjdk-${OPENJDK_SLOT_VERSION}/

	for jbin in `ls /usr/${BASELIB}/openjdk-${OPENJDK_SLOT_VERSION}/bin`
	do
		buildah run $CONTAINER -- ln -s /usr/${BASELIB}/openjdk-${OPENJDK_SLOT_VERSION}/bin/${jbin} /usr/bin/${jbin}
	done

	# clean and commit
	#_cleanup_utils $CONTAINER
	buildah commit $CONTAINER gentoo-container-openjdk:${OPENJDK_VERSION_LABEL}
	buildah rm $CONTAINER
}

push_images(){
	buildah push ${REGISTRY_ARGS} gentoo-container-base:latest ${REGISTRY_URL}/gentoo-container-base:latest
	buildah push ${REGISTRY_ARGS} gentoo-container-gcc:latest ${REGISTRY_URL}/gentoo-container-gcc:latest
	buildah push ${REGISTRY_ARGS} gentoo-container-python:latest ${REGISTRY_URL}/gentoo-container-python:latest
	buildah push ${REGISTRY_ARGS} gentoo-container-nodejs:latest ${REGISTRY_URL}/gentoo-container-nodejs:latest
	buildah push ${REGISTRY_ARGS} gentoo-container-zeromq:latest ${REGISTRY_URL}/gentoo-container-zeromq:latest
	buildah push ${REGISTRY_ARGS} gentoo-container-packer:latest ${REGISTRY_URL}/gentoo-container-packer:latest
	buildah push ${REGISTRY_ARGS} gentoo-container-openssh:latest ${REGISTRY_URL}/gentoo-container-openssh:latest
	buildah push ${REGISTRY_ARGS} gentoo-container-git:latest ${REGISTRY_URL}/gentoo-container-git:latest
	buildah push ${REGISTRY_ARGS} gentoo-container-openjdk:latest ${REGISTRY_URL}/gentoo-container-openjdk:latest
	buildah push ${REGISTRY_ARGS} gentoo-container-ruby:latest ${REGISTRY_URL}/gentoo-container-ruby:latest
	buildah push ${REGISTRY_ARGS} gentoo-container-php:latest ${REGISTRY_URL}/gentoo-container-php:latest
}

gentoo_container_base
gentoo_container_python
gentoo_container_openssh_client
gentoo_container_nginx
gentoo_container_git
gentoo_container_ruby
gentoo_container_nodejs
gentoo_container_php_fpm
gentoo_container_zeromq
gentoo_container_packer
gentoo_container_busybox
gentoo_container_openjdk

