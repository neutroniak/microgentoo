#!/bin/sh

bars() {
	COLOR_NC='\e[0m' # No Color
	COLOR_BLACK='\e[0;30m'
	COLOR_GRAY='\e[1;30m'
	COLOR_RED='\e[0;31m'
	COLOR_LIGHT_RED='\e[1;31m'
	COLOR_GREEN='\e[0;32m'
	COLOR_LIGHT_GREEN='\e[1;32m'
	COLOR_BROWN='\e[0;33m'
	COLOR_YELLOW='\e[1;33m'=
	COLOR_BLUE='\e[0;34m'
	COLOR_LIGHT_BLUE='\e[1;34m'
	COLOR_PURPLE='\e[0;35m'
	COLOR_LIGHT_PURPLE='\e[1;35m'
	COLOR_CYAN='\e[0;36m'
	COLOR_LIGHT_CYAN='\e[1;36m'
	COLOR_LIGHT_GRAY='\e[0;37m'
	COLOR_WHITE='\e[1;37m'

	BARS="==============================================================="

	if [[ "x$1" == "xgreen" ]]; then
		echo -e "${COLOR_GREEN}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xlight_green" ]]; then
		echo -e "${COLOR_LIGHT_GREEN}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xbrown" ]]; then
		echo -e "${COLOR_BROWN}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xyellow" ]]; then
		echo -e "${COLOR_YELLOW}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xred" ]]; then
		echo -e "${COLOR_RED}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xlight_red" ]]; then
		echo -e "${COLOR_LIGHT_RED}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xblue" ]]; then
		echo -e "${COLOR_BLUE}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xlight_blue" ]]; then
		echo -e "${COLOR_LIGHT_BLUE}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xgray" ]]; then
		echo -e "${COLOR_GRAY}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xlight_gray" ]]; then
		echo -e "${COLOR_LIGHT_GRAY}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xcyan" ]]; then
		echo -e "${COLOR_CYAN}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xlight_cyan" ]]; then
		echo -e "${COLOR_LIGHT_CYAN}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xpurple" ]]; then
		echo -e "${COLOR_PURPLE}${BARS}${COLOR_NC}"
	elif [[ "x$1" == "xlight_purple" ]]; then
		echo -e "${COLOR_LIGHT_PURPLE}${BARS}${COLOR_NC}"
	else
		echo -e "${COLOR_WHITE}${BARS}${COLOR_NC}"
	fi
}

print_header() {
	source ./.microgentoo
	bars ${PROJECT_COLOR}
	echo -e "Building dir `pwd`"
	echo -e "nature: ${PROJECT_NATURE}"
	echo -e "config: ${MICROGENTOO}"
	bars ${PROJECT_COLOR}
}

function _copy_ldd() {
	LDD_SOURCE=$1
	LDD_DEST=$2
	LDD_FILTER=$3
    BINFILE=$(find $LDD_SOURCE -type f -iname "${LDD_FILTER}" -executable)
	SAVEIFS=$IFS
	IFS=$'\n'
	ARR=(`ldd $BINFILE`)
	IFS=$SAVEIFS
    for (( i=0; i<${#ARR[@]}; i++ ))
    do
    	LIBFILE=$(echo "${ARR[$i]}"|awk '{print $3}')
        if [ "$LIBFILE" != "" ] && [ "$LIBFILE" != "ldd" ]; then
			mkdir -p $LDD_DEST
			echo "LDD: Copying $LIBFILE $LDD_DEST"
			cp --parents $LIBFILE $LDD_DEST
        fi
    done
}

_etc_profile() {
	source /etc/profile.env
}

_export_make_conf() {
	source /etc/portage/make.conf

	if [ ! -f /tmp/emerge.info.out ]; then
		echo "Creating emerge cache file"
		emerge --info --verbose > /tmp/emerge.info.out
	fi

	export CHOST=$(cat /tmp/emerge.info.out| grep -w CHOST=|sed 's/CHOST="//g'|sed 's/"//g')
	export CC=$(cat /tmp/emerge.info.out| grep -w CC=|sed 's/CC="//g'|sed 's/"//g')
	export CXX=$(cat /tmp/emerge.info.out| grep -w CXX=|sed 's/CXX="//g'|sed 's/"//g')
	export LDFLAGS=$(cat /tmp/emerge.info.out| grep -w LDFLAGS=|sed 's/LDFLAGS="//g'|sed 's/"//g')
	export CFLAGS=$(cat /tmp/emerge.info.out| grep -w CFLAGS=|sed 's/CFLAGS="//g'|sed 's/"//g')
	export CXXFLAGS=$(cat /tmp/emerge.info.out| grep -w CXXFLAGS=|sed 's/CXXFLAGS="//g'|sed 's/"//g')
	export AR=$(cat /tmp/emerge.info.out| grep -w AR=|sed 's/AR="//g'|sed 's/"//g')
	export NM=$(cat /tmp/emerge.info.out| grep -w NM=|sed 's/NM="//g'|sed 's/"//g')
	export RANLIB=$(cat /tmp/emerge.info.out| grep -w RANLIB=|sed 's/RANLIB="//g'|sed 's/"//g')
	export CXXSTDLIB=$(cat /tmp/emerge.info.out| grep -w CXXSTDLIB=|sed 's/CXXSTDLIB="//g'|sed 's/"//g')
	export LLVM_USE_LIBCXX=$(cat /tmp/emerge.info.out| grep -w LLVM_USE_LIBCXX=|sed 's/LLVM_USE_LIBCXX="//g'|sed 's/"//g')
	export ADDR2LINE=$(cat /tmp/emerge.info.out| grep -w ADDR2LINE=|sed 's/ADDR2LINE="//g'|sed 's/"//g')
	export READELF=$(cat /tmp/emerge.info.out| grep -w READELF=|sed 's/READELF="//g'|sed 's/"//g')
	export OBJDUMP=$(cat /tmp/emerge.info.out| grep -w OBJDUMP=|sed 's/OBJDUMP="//g'|sed 's/"//g')
}

_create_container() {

	DISTDIR=$1
	BPACKAGE=$2
	BVERSION=$3

	if [ -f "."$4".err" ]; then
		echo "Build was not successful.. Container will not be created"
		rm "."$4".err"
		exit;
	fi

	if [ -f Containerfile ]; then
		buildah bud \
			--build-arg-file .microgentoo \
			--build-arg DISTDIR=$DISTDIR \
			--build-arg MICROGENTOO=$MICROGENTOO_PREFIX \
			-f Containerfile \
			-t localhost/${CONTAINER_PATH}/${BPACKAGE}:${BVERSION}

		CPORTS=$(grep EXPOSE Containerfile |awk '{print "-p "$2":"$2'})
		CPORTSL=$(echo $CPORTS|sed "s/\n\t\r//g")	
		#for (( i=0; i<${#CPORTS[@]}; i++ ))
		#do
		#	 ALLPORTS+=${CPORTS[i]}
		#done

		echo "###############################"
		echo "To test the new container with podman, execute:"
		echo ""
		echo "podman run ${CPORTSL} -e PYTHONUNBUFFERED=1 --rm ${CONTAINER_PATH}/${BPACKAGE}:${BVERSION}"
		echo ""
		echo "###############################"

		if [ ! -z "${REGISTRY_URL}" ]; then
			buildah --tls-verify=false push ${REGISTRY_ARGS} ${CONTAINER_PATH}/$BPACKAGE:$BVERSION ${REGISTRY_URL}/${CONTAINER_PATH}/$BPACKAGE:$BVERSION
		fi
	fi
}

build_meson() {
	print_header
	_etc_profile
	_export_make_conf

	export CHOST=$(emerge --info |grep CHOST|sed 's/CHOST="//g'|sed 's/"//g')
	export NCPU=$(grep processor /proc/cpuinfo |wc -l)


	if [[ ${MG_BUILD} =~ "debug" ]]; then
		BUILDTYPE='debug'
	else
		BUILDTYPE='release'
	fi

	export BUILD="build/${CHOST}/${BUILDTYPE}"

	meson setup --buildtype=${BUILDTYPE} ${BUILD}
	cd ${BUILD} && ninja reconfigure && ninja -v -j${NCPU}
	cd $OLDPWD
	mkdir -p ${BUILD}/dist
	meson install --strip --destdir dist -C ${BUILD}
	meson introspect --projectinfo ${BUILD} > ${BUILD}/introspect.json 
	
	if [ ${BUILDTYPE} == "release" ]; then
		_copy_ldd ${BUILD} ${BUILD}/dist '*'
	fi

	echo $BUILD > "."${1}
}

build_autotools() {
	print_header
	_etc_profile
	_export_make_conf

	export CHOST=$(emerge --info |grep CHOST|sed 's/CHOST="//g'|sed 's/"//g')
	export NCPU=$(grep processor /proc/cpuinfo |wc -l)
	export NCPU=$(echo ${NCPU}/2|bc)

	if [[ ${MG_BUILD} =~ "debug" ]]; then
		BUILDTYPE='debug'
	else
		BUILDTYPE='release'
	fi

	./configure ${AUTOTOOLS_CONFIGURE} && make -j${NCPU}

	echo $BUILD > "."${1}
}

build_cmake() {
	print_header
	_etc_profile
	_export_make_conf

	export CHOST=$(emerge -- --info |grep CHOST|sed 's/CHOST="//g'|sed 's/"//g')
	export NCPU=$(grep processor /proc/cpuinfo |wc -l)

	if [[ ${MG_BUILD} =~ "debug" ]]; then
		BUILDTYPE='debug'
	else
		BUILDTYPE='release'
	fi

	export BUILD="build/${CHOST}/${BUILDTYPE}"

	mkdir -p $BUILD
	mkdir -p $BUILD/dist
	cd ${BUILD} && cmake -DCMAKE_BUILD_TYPE=${BUILDTYPE} -DCMAKE_INSTALL_PREFIX="./dist" ../../../ && make VERBOSE=1 -j${NCPU} && make install
	cd $OLDPWD
	#mkdir -p ${BUILD}/dist
	
	#meson install --strip --destdir dist -C ${BUILD}
	#meson introspect --projectinfo ${BUILD} > ${BUILD}/introspect.json 
	
	if [ ${BUILDTYPE} == "release" ]; then
		_copy_ldd ${BUILD} ${BUILD}/dist '*'
	fi

	echo $BUILD > "."${1}
}

build_rust() {
	print_header
	_export_make_conf
	_etc_profile

	export NCPU=$(grep processor /proc/cpuinfo |wc -l)
	export NCPU=$(echo ${NCPU}/2|bc)

	if [[ ${MG_BUILD} =~ "debug" ]]; then
		cargo build -j${NCPU}
	else
		cargo build -r -j${NCPU}
	fi

	_build_status $? $1
	rm -rf build
	mkdir -p build
	cargo install -j${NCPU} --path . --root build
	_copy_ldd build build "*"
}

build_nodejs() {
	print_header
	_export_make_conf
	_etc_profile
	npm run build
	cd build
	npm i --omit=dev
}

build_python() {
	print_header
	export BUILD=.
	_export_make_conf
	_etc_profile

	rm -rf build
	mkdir -p build
	cp -r src *.py requirements.txt build
	cd build
	python -m venv venv
	./venv/bin/pip install -r requirements.txt

	_copy_ldd venv/lib dist "*.so"
	_copy_ldd dist dist "*.so"
}


build_htmx() {
	print_header
	_export_make_conf
	rm -rf dist
	mkdir -p dist
	npm run dist
}

build_stricter() {
	print_header
	_export_make_conf
	rm -rf build
	mkdir -p build
	STRICTER=$(readlink stricter)
	cp -r classes *.php js views themes lang startup.sh etc .libs build
	cp -r $STRICTER build/stricter
	cd build
	rm -rf views/smarty/templates_c/* views/smarty/cache/*
	cp /usr/bin/tail .
}

build_go() {
	print_header
	_export_make_conf
	_etc_profile
	make build

	_copy_ldd build build "*"
}

_build_status() {
	if [ "x$1" == "x0" ]; then
		echo "build sucessfull.."
	else
		echo "build error.."
		echo 1 > "."$2".err"
	fi
}

########### callers #############################
function call_python() {
	chroot $CHROOTDIR /bin/bash -c "cd $PWD && $0 python"

	BVERSION=$(python setup.py --version)
	BPACKAGE=$(python setup.py --name)
	DISTDIR="build/dist"

	_create_container $DISTDIR $BPACKAGE $BVERSION

	exit;
}

function call_react() {
	chroot $CHROOTDIR /bin/bash -c "cd $PWD && $0 nodejs"


	BVERSION=$(cat package.json|python -c "import json; import sys; print(json.load(sys.stdin)['version'])")
	BPACKAGE=$(cat package.json|python -c "import json; import sys; print(json.load(sys.stdin)['name'])")
	DISTDIR="build/dist"
	_create_container $DISTDIR $BPACKAGE $BVERSION

	exit;
}

function call_nodejs() {
	chroot $CHROOTDIR /bin/bash -c "cd $PWD && $0 nodejs"

	BVERSION=$(cat package.json|python -c "import json; import sys; print(json.load(sys.stdin)['version'])")
	BPACKAGE=$(cat package.json|python -c "import json; import sys; print(json.load(sys.stdin)['name'])")
	DISTDIR="build/dist"
	_create_container $DISTDIR $BPACKAGE $BVERSION

	exit;
}

function call_meson() {
	UUID=$(uuidgen)

	chroot $CHROOTDIR /bin/bash -c "cd $PWD && $0 meson ${UUID}"

	export BUILD=$(cat "."${UUID})

	export EXENAME=$(jq '.[0]."name"' < $BUILD/meson-info/intro-targets.json|sed 's/"//g')

	BVERSION=$(cat ${BUILD}/introspect.json|python -c "import json; import sys; print(json.load(sys.stdin)['version'])")
	BPACKAGE=$(cat ${BUILD}/introspect.json|python -c "import json; import sys; print(json.load(sys.stdin)['descriptive_name'])")
	DISTDIR=$BUILD"/dist"

	if [ "x$MG_BUILD" == "xdebug" ]; then
		chroot $CHROOTDIR /bin/bash -c "cd $PWD/$BUILD && gdb ./$EXENAME"
	elif [ "x$MG_BUILD" == "xvalgrind" ]; then
		chroot $CHROOTDIR /bin/bash -c "cd $PWD/$BUILD && valgrind --leak-check=full --show-leak-kinds=all ./${EXENAME}"
	else
		_create_container $DISTDIR $BPACKAGE $BVERSION ${UUID}
	fi

	rm "."${UUID}
	exit;
}

function call_cmake() {
	UUID=$(uuidgen)
	chroot $CHROOTDIR /bin/bash -c "cd $PWD && $0 cmake ${UUID}"

	export BUILD=$(cat "."${UUID})
	
	EXENAME=`grep -i add_exec src/CMakeLists.txt | sed 's/add_executable(//g'|sed 's/ .*$//g'`

	#BVERSION=$(cat ${BUILD}/introspect.json|python -c "import json; import sys; print(json.load(sys.stdin)['version'])")
	#BPACKAGE=$(cat ${BUILD}/introspect.json|python -c "import json; import sys; print(json.load(sys.stdin)['descriptive_name'])")
	DISTDIR=$BUILD"/dist"

	if [ "x$MG_BUILD" == "xdebug" ]; then
		chroot $CHROOTDIR /bin/bash -c "cd $PWD/$BUILD && gdb src/$EXENAME"
	elif [ "x$MG_BUILD" == "xvalgrind" ]; then
		chroot $CHROOTDIR /bin/bash -c "cd $PWD/$BUILD && valgrind --leak-check=full --show-leak-kinds=all src/${EXENAME}"
	else
		_create_container $DISTDIR $BPACKAGE $BVERSION ${UUID}
	fi

	rm "."${UUID}
	exit;
}

function call_rust() {
	chroot $CHROOTDIR /bin/bash -c "cd $PWD && $0 rust"

	BVERSION=$(cat Cargo.toml|python -c 'import tomli; fp=open("Cargo.toml", "rb"); t = tomli.load(fp); print(t["package"]["version"]);')
	BPACKAGE=$(cat Cargo.toml|python -c 'import tomli; fp=open("Cargo.toml", "rb"); t = tomli.load(fp); print(t["package"]["name"]);')
	DISTDIR="dist"

	if [ "x$MG_BUILD" == "xdebug" ]; then
		#chroot $CHROOTDIR /bin/bash -c "cd $PWD/$BUILD && rust-gdb build/bin/$BPACKAGE"
		chroot $CHROOTDIR /bin/bash -c "cd $PWD && rust-gdb target/debug/$BPACKAGE"
	elif [ "x$MG_BUILD" == "xrelease" ]; then
		_create_container $DISTDIR $BPACKAGE $BVERSION
	else
		_create_container $DISTDIR $BPACKAGE $BVERSION
	fi

	exit;
}

function call_go() {
	UUID=$(uuidgen)
	chroot $CHROOTDIR /bin/bash -c "cd $PWD && $0 go ${UUID}"

	DISTDIR=$BUILD"/build"
	BVERSION=$(grep --regex="^VERSION" Makefile|awk -F'=' '{print $2}')
	BPACKAGE=$(grep --regex="^NAME" Makefile|awk -F'=' '{print $2}')
	echo $BVERSION
	echo $BPACKAGE
	_create_container $DISTDIR $BPACKAGE $BVERSION ${UUID}

	exit;
}

function call_stricter() {
	chroot $CHROOTDIR /bin/bash -c "cd $PWD && $0 stricter"

	DISTDIR="build"

	BVERSION=$(grep PACKAGE_VERSION package.php |sed 's/const //g'|awk '{print $1}'|awk -F'=' '{print $2}'|sed 's/[";]//g')
	BPACKAGE=$(grep PACKAGE_NAME package.php |sed 's/const //g'|awk '{print $1}'|awk -F'=' '{print $2}'|sed 's/[";]//g')
	
	_create_container $DISTDIR $BPACKAGE $BVERSION ${UUID}
	rm tail
	exit;
}

function call_htmx() {
	chroot $CHROOTDIR /bin/bash -c "cd $PWD && $0 htmx"

	DISTDIR="dist"

	BVERSION=$(grep PACKAGE_VERSION package.php |sed 's/const //g'|awk '{print $1}'|awk -F'=' '{print $2}'|sed 's/[";]//g')
	BPACKAGE=$(grep PACKAGE_NAME package.php |sed 's/const //g'|awk '{print $1}'|awk -F'=' '{print $2}'|sed 's/[";]//g')
	
	_create_container $DISTDIR $BPACKAGE $BVERSION ${UUID}
	rm tail
	exit;
}

function call_autotools() {
	UUID=$(uuidgen)

	chroot $CHROOTDIR /bin/bash -c "cd $PWD && $0 autotools ${UUID}"

	export BUILD=$(cat "."${UUID})

	export EXENAME=${AUTOTOOLS_EXECUTABLE}

	DISTDIR=$BUILD"/dist"

	if [ "x$MG_BUILD" == "xrun" ]; then
		chroot $CHROOTDIR /bin/bash -c "cd $PWD/$BUILD && gdb ./$EXENAME"
	elif [ "x$MG_BUILD" == "xvalgrind" ]; then
		chroot $CHROOTDIR /bin/bash -c "cd $PWD/$BUILD && valgrind --leak-check=full --show-leak-kinds=all ./${EXENAME}"
	else
		echo "no container for autotools"
		#_create_container $DISTDIR $BPACKAGE $BVERSION ${UUID}
	fi

	rm "."${UUID}
	exit;
}

#########################################################################
#########################################################################
############################  main  #####################################
#########################################################################
#########################################################################

# means that this is script is being called from the chrooted environment.. build and exit
if [ $1 ]; then
	build_${1} $2
	exit;
else
	source ./.microgentoo

	if [ -f /etc/microgentoo/${MICROGENTOO} ]; then
		source /etc/microgentoo/${MICROGENTOO}
		export CHROOTDIR=${ROOTDIR:-'/'}
	fi

	export MICROGENTOO_PREFIX=$PREFIX

	if [ "$PROJECT_NATURE" == "htmx" ]; then 
		call_htmx
	elif [ "$PROJECT_NATURE" == "python" ]; then 
		call_python
	elif [ "$PROJECT_NATURE" == "rust" ]; then
		call_rust
	elif [ "$PROJECT_NATURE" == "react" ]; then
		call_react
	elif [ "$PROJECT_NATURE" == "nodejs" ]; then
		call_nodejs
	elif [ "$PROJECT_NATURE" == "meson" ]; then
		call_meson
	elif [ "$PROJECT_NATURE" == "cmake" ]; then
		call_cmake
	elif [ "$PROJECT_NATURE" == "go" ]; then
		call_go
	elif [ "$PROJECT_NATURE" == "stricter" ]; then
		call_stricter
	elif [ "$PROJECT_NATURE" == "autotools" ]; then
		call_autotools
	fi
fi

