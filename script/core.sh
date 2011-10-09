#! /usr/bin/env bash

PKGNAME=tjyMOD
VERSION=0.1
DIRS="system data kernel META-INF"
BASEROM_DIRS="system data META-INF"
KERNEL_DIRS="system data kernel"

DOWN_DIR="$workdir/../download"
TEMP_DIR="$workdir/../tmp"
OUT_DIR="$workdir/../out/${PKGNAME}_$(date +%Y%m%d)"
EXTR_DIR="$workdir/../extra"

KERNELBASE=https://dl.dropbox.com/s/2lar8mywh2u9ctk  # lordmodUEv7.2-CFS-b13.zip?dl=1
ROMBASE=http://download.cyanogenmod.com/get          # cm_ace_full-XXX.zip

die () {
	echo -e "\033[1;30m>\033[0;31m>\033[1;31m> ERROR:\033[0m ${@}" && exit 1
}

einfo () {
	echo -ne "\033[1;30m>\033[0;36m>\033[1;36m> \033[0m${@}\n"
}

ewarn () {
	echo -ne "\033[1;30m>\033[0;33m>\033[1;33m> \033[0m${@}\n"
}

ewarn_n () {
	echo -ne "\033[1;30m>\033[0;33m>\033[1;33m> \033[0m${@} "
}

dexec () {
    CMD="$@"
    echo "Exec:$CMD" >> $LOG
    eval $CMD >> $LOG 2>&1 || die "Die:$CMD"
}

unpack () {
    ewarn "unpack: $(readlink -f $1)"
    test -d $TEMP_DIR || mkdir -p $TEMP_DIR
    out="$(basename $1)"
    dexec unzip -x $1 -d $TEMP_DIR/$out >> $LOG 2>&1
}

download () {
    url=$1
    target=$2

    test -d $DOWN_DIR || mkdir -p $DOWN_DIR
    test $verbose = 0 && quiet="-q" || quiet=""

    ewarn "Download from $url"
    dexec wget $url -O $DOWN_DIR/$target $quiet
    md5sum $DOWN_DIR/$target > $DOWN_DIR/${target}.sum
}

kernel_download () {
    target=$1

    
    if [ -f $DOWN_DIR/${target}.sum ]; then
        cd $DOWN_DIR
        md5sum --status --check ${target}.sum
        case "$?" in
            0) ewarn "md5sum:$target checked, cached use.";;
            1) download $KERNELBASE/${target}?dl=1 $target;;
        esac
        cd - > /dev/null
    else
        download $KERNELBASE/${target}?dl=1 $target
    fi
    unpack $DOWN_DIR/$target
}

baserom_download () {
    target=$1

    if [ -f $DOWN_DIR/${target}.sum ]; then
        cd $DOWN_DIR
        md5sum --status --check ${target}.sum
        case "$?" in
            0) ewarn "md5sum:$target checked, cached use.";;
            1) download $ROMBASE/$target $target;;
        esac
        cd - > /dev/null
    else
        download $ROMBASE/$target $target
    fi
    unpack $DOWN_DIR/$target
}

get_kernel () {
    arg=$1
    kernel=$(readlink -f $arg)
    test x"" = x"$kernel" && die "can not get $1"
    target=$(basename $kernel)

    ewarn "Get Kernel: $target"
    test -f $kernel && unpack $kernel || kernel_download $target
}

get_baserom () {
    arg=$1
    baserom=$(readlink -f $arg)
    test x"" = x"$baserom" && die "can not get $1"
    target=$(basename $baserom)

    ewarn "Get ROM: $target"
    test -f $baserom && unpack $baserom || baserom_download $target
}

cleanup () {
    rm -fr $TEMP_DIR
}

all_cleanup () {
    cleanup
    rm -fr $DOWN_DIR
}

merge () {
    target=$1
    dirs="$2"

    for t in $target
    do
        ewarn_n "Reconstrunction: \033[1;31m$(basename $t)\033[0m [$dirs]\n * "
        (
            cd $t
            for d in $dirs
            do
                if test -d $d; then
                    echo -ne "\033[1;36m$(basename $d)\033[0m "
                    tar cf - $d | (cd $OUT_DIR; tar xfv -) >> $LOG 2>&1
                fi
            done
        )
        echo -ne "\n"
        rm -fr $t
    done
}

strip_modules () {
    rm -fr $OUT_DIR/system/lib/modules
}

mix_extra () {
    ewarn_n "Mixup: $(readlink -f $EXTR_DIR)\n * "
    cd $EXTR_DIR
    for d in $DIRS
    do
        if test -d $d; then
            echo -ne "\033[1;36m$(basename $d)\033[0m "
            tar cf - $d | (cd $OUT_DIR; tar xvf -) >> $LOG 2>&1
        fi
    done
    echo -ne "\n"

    ewarn_n "APPEND: $(readlink -f $OUT_DIR)\n * "
    cd $OUT_DIR
    for f in $(find . -name "*.append")
    do
        test -f $f && (
            name=$(basename $f .append)
                tdir=$(dirname $f)
                echo -ne "\033[1;36m$name\033[0m "
                cat ${tdir}/${name} $f > ${name}.new
                mv ${name}.new ${tdir}/${name}
        )
        rm -f $f
    done
    echo -ne "\n"
}

build () {
    baserom=$(basename $1)
    kernel=$(basename $2)

    test -d $OUT_DIR && rm -fr $OUT_DIR
    mkdir -p $OUT_DIR

    merge $TEMP_DIR/$baserom "$BASEROM_DIRS"
    strip_modules
    merge $TEMP_DIR/$kernel "$KERNEL_DIRS"

    mix_extra
}
