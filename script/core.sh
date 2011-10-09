#! /usr/bin/env bash

PKGNAME=tjyMOD
VERSION=0.1
LOCALE=JAPAN # sdcard/gpsconf/..

giturl="git://github.com/ac1965/DD.git"
default_kernel="lordmodUEv7.2-CFS-b13.zip"
default_baserom="cm_ace_full-220.zip"
KERNELBASE=https://dl.dropbox.com/s/2lar8mywh2u9ctk  # lordmodUEv7.2-CFS-b13.zip?dl=1
ROMBASE=http://download.cyanogenmod.com/get          # cm_ace_full-XXX.zip

DIRS="system data kernel META-INF"
BASEROM_DIRS="system data META-INF"
KERNEL_DIRS="system data kernel"
CLEAN_LIST="kernel \
            system/app/Provision.apk \
            system/app/ADWLauncher.apk \
            system/app/MarketUpgrader.apk \
            setup/kor" # for the moment

DOWN_DIR="$workdir/../download"
ART_DIR="$workdir/../artwork"
TEMP_DIR="$workdir/../tmp"
OUT_DIR="$workdir/../out/${PKGNAME}_$dt"
EXTR_DIR="$workdir/../extra"
TOOLS_DIR="$workdir/../tools"
GPS_DIR="$workdir/../sdcard/gpsconf"

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
        ewarn_n "Reconstrunction: \033[0;31m$(basename $t)\033[0m \033[1;30m[$dirs]\033[0m\n * "
        (
            cd $t
            for d in $dirs
            do
                if test -d $d; then
                    echo -ne "\033[0;36m$(basename $d)\033[0m "
                    tar cf - $d | (cd $OUT_DIR; tar xfv -) >> $LOG 2>&1
                fi
            done
        )
        echo -ne "\n"
    done

}

remove () {
    for t in "$@"
    do
        rm -fr $t
    done
}

pretty_fix () {
    suffix=$1

    cd $OUT_DIR
    for f in $(find . -name "*.${suffix}")
    do
        test -f $f && (
            name=$(basename $f .${suffix})
            tdir=$(dirname $f)
            echo -ne "\033[0;36m$name\033[0m "
            if [ x"$suffix" = x"prepend" ]; then
                cat $f ${tdir}/${name} > ${name}.new
            else
                cat ${tdir}/${name} $f > ${name}.new
            fi
            mv ${name}.new ${tdir}/${name}
        )
        rm -f $f
    done
    echo -ne "\n"
}

mix_extra () {
    ewarn_n "Mixup: $(readlink -f $EXTR_DIR)\n * "
    cd $EXTR_DIR
    for d in $DIRS
    do
        if test -d $d; then
            echo -ne "\033[0;36m$(basename $d)\033[0m "
            tar cf - $d | (cd $OUT_DIR; tar xvf -) >> $LOG 2>&1
        fi
    done
    echo -ne "\n"

    ewarn_n "PRE: $(readlink -f $OUT_DIR)\n * "
    pretty_fix "prepend"
    ewarn_n "APPEND: $(readlink -f $OUT_DIR)\n * "
    pretty_fix "append"
}

mkbootimg () {
    OLDIMG=$1
    ZIMAGE=$2
    BOOT=$3
    
    T="$TEMP_DIR/mkbootimg"

    test -d $T || mkdir -p $T
    dexec dd if=$OLDIMG of=$TEMP_DIR/boot.img
    dexec $TOOLS_DIR/unpackbootimg -i $TEMP_DIR/boot.img -o $T
    dexec $TOOLS_DIR/mkbootimg --kernel $ZIMAGE --ramdisk $T/boot.img-ramdisk.gz \
        --cmdline $(cat $T/boot.img-cmdline) \
        --base $(cat $T/boot.img-base) \
        --output $BOOT
    rm -fr $T $TEMP_DIR/boot.img
}

zipped_sign () {
    NAME=${PKGNAME}_${dt}
    ZIPF="$(readlink -f $OUT_DIR/../${NAME}.zip)"
    OUTF="$(readlink -f $OUT_DIR/../${NAME}.signed.zip)"
    ewarn_n "BUILD ROM: $(basename $OUTF)\n * "
    cd $OUT_DIR
    test -f $ZIPF && rm -f $ZIPF
    echo -ne "\033[0;36mcustomize ("
    sed -i 's/DD_VERSION/'${PKGNAME}-v${VERSION}_${dt}'/' system/build.prop
    cat $ART_DIR/logo.txt META-INF/com/google/android/updater-script > _u
    mv _u META-INF/com/google/android/updater-script
    sed -i '/mount("ext4", "EMMC", "\/dev\/block\/mmcblk0p25",/a mount("ext4", "EMMC", "/dev/block/mmcblk0p26", "/data");' \
        META-INF/com/google/android/updater-script
    sed -i '/package_extract_dir("system",/a package_extract_dir("data","/data");' \
        META-INF/com/google/android/updater-script
    sed -i '/umount("\/system",/i umount("/data");' \
        META-INF/com/google/android/updater-script
    test -f $GPS_DIR/${LOCALE}.zip && \
        unzip $GPS_DIR/${LOCALE}.zip -d $TEMP_DIR/gps >> $LOG 2>&1
    test -f $TEMP_DIR/gps/system/etc/gps.conf && \
        cp $TEMP_DIR/gps/system/etc/gps.conf $OUT_DIR/system/etc
    test -d $TEMP_DIR/gps && rm -fr $TEMP_DIR/gps
    
    echo "BASEROM : $(basename $baserom_file)" > $OUT_DIR/build_${NAME}.txt
    echo "KERNEL  : $(basename $kernel_file)" >> $OUT_DIR/build_${NAME}.txt
    for f in $CLEAN_LIST
    do
        test -f $f && (rm -f $f; echo -ne "$f ")
        test -d $f && (rm -fr $f; echo -ne "$f ")
    done
    echo -ne ")"
    echo -ne " => zipped"
    dexec zip -r9 $ZIPF . >> $LOG 2>&1
    echo -ne " => sign-zipped\033[0m"
    dexec java -jar $TOOLS_DIR/signapk.jar $TOOLS_DIR/certification.pem $TOOLS_DIR/key.pk8 \
        $ZIPF $OUTF && rm -f $ZIPF
    echo -ne "\n"
}

build () {
    baserom=$(basename $1)
    kernel=$(basename $2)

    test -d $OUT_DIR && rm -fr $OUT_DIR
    mkdir -p $OUT_DIR


    merge $TEMP_DIR/$baserom "$BASEROM_DIRS"
    test -d $OUT_DIR/system/lib/modules && rm -fr $OUT_DIR/system/lib/modules
    merge $TEMP_DIR/$kernel "$KERNEL_DIRS"
    mkbootimg $TEMP_DIR/$baserom/boot.img $TEMP_DIR/$kernel/kernel/zImage $OUT_DIR/boot.img
    remove $TEMP_DIR/$baserom $TEMP_DIR/$kernel

    mix_extra
    zipped_sign
}
