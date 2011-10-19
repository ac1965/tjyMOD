#! /usr/bin/env bash

PKGNAME=tjyMOD
VERSION=0.2
LOCALE=JAPAN # sdcard/gpsconf/..

giturl="git://github.com/ac1965/tjyMOD.git"
default_kernel="update_2.6.35-BFS-WIP-AUFS_201110161155.zip"
default_baserom="cm_ace_full-227.zip"
default_gapps="gapps-gb-20110930-237-signed.zip"
KERNELBASE=https://dl.dropbox.com/s/2lar8mywh2u9ctk  # lordmodUEv7.2-CFS-b13.zip?dl=1
ROMBASE=http://download.cyanogenmod.com/get          # cm_ace_full-XXX.zip
GAPPS_URL=http://goo-inside.me/gapps                 # gapps

DIRS="system data setup kernel META-INF"
BASEROM_DIRS="system data META-INF"
KERNEL_DIRS="system data kernel"
GAPPS_DIRS="system data"
CLEAN_LIST="kernel \
            system/app/Provision.apk \
            system/app/ADWLauncher.apk \
            system/app/MarketUpgrader.apk \
            setup/kor" # for the moment

O="$workdir/../out"
DOWN_DIR="$workdir/../download"
ART_DIR="$workdir/../artwork"
TEMP_DIR="$workdir/../tmp"
OUT_DIR="${O}/${PKGNAME}_$dt"
BASE_DIR="$workdir/../base"
EXTR_DIR="$workdir/../extra"
TOOLS_DIR="$workdir/../tools"
SDCARD_DIR="${EXTR_DIR}/sdcard"
GPS_DIR="${SDCARD_DIR}/tjyMOD/gpsconf"

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

usage () {
    cat <<EOF
Usage:
   $PKGNAME (-v) all (--kernel KERNEL_FILE) (--baserom ROM_FILE) (--gapps GAPS_FILE) (--gps-locale LOCALE) (--ril-versio VER)
   $PKGNAME (-v) clean

EOF
    exit
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

pretty_download () {
    target=$1
    url=$2

    if [ -f $DOWN_DIR/${target}.sum ]; then
        cd $DOWN_DIR
        md5sum --status --check ${target}.sum
        case "$?" in
            0) ewarn "md5sum:$target checked, cached use.";;
            1) download $url $target;;
        esac
        cd - > /dev/null
    else
        download $url $target
    fi
    unpack $DOWN_DIR/$target

}

pretty_get () {
    arg=$1
    which=$2 #
    
    fname=$(readlink -f $arg)
    test x"" = x"$fname" && die "can not get $arg"
    target=$(basename $fname)
    
    ewarn "Get $which: $target"
    if [ $which = "kernel" ]; then
        url="$KERNELBASE/${target}?dl=1"
    elif [ $which = "baserom" ]; then
        url="$ROMBASE/$target"
    elif [ $which = "gapps" ]; then
        url="$GAPPS_URL/$target"
    else
        die "pretty_get()"
    fi
    test -f $fname && unpack $fname || pretty_download $target $url
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

pretty_extra () {
	cd $1
    for d in $DIRS
    do
        if test -d $d; then
            echo -ne "\033[0;36m$(basename $d)\033[0m "
            tar cf - $d | (cd $OUT_DIR; tar xvf -) >> $LOG 2>&1
        fi
    done
}

mix_extra () {
    ewarn_n "Mixup: $(readlink -f $BASE_DIR)\n * "
    pretty_extra $BASE_DIR
    pretty_extra $EXTR_DIR
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
    NAME=${PKGNAME}-${dt}
    ZIPF="$(readlink -f $OUT_DIR/../${NAME}.zip)"
    OUTF="$(readlink -f $OUT_DIR/../${NAME}.signed.zip)"
    ewarn_n "BUILD ROM: $(basename $OUTF)\n * "
    cd $OUT_DIR
    test -f $ZIPF && rm -f $ZIPF
    echo -ne "\033[0;36mcustomize"
    sed -i 's/DD_VERSION/'${PKGNAME}-v${VERSION}_${dt}'/' system/build.prop
    cat $ART_DIR/logo.txt META-INF/com/google/android/updater-script > _u
    mv _u META-INF/com/google/android/updater-script
    sed -i '/mount("ext4", "EMMC", "\/dev\/block\/mmcblk0p25",/a \
mount("ext4", "EMMC", "/dev/block/mmcblk0p26", "/data");' \
        META-INF/com/google/android/updater-script
    sed -i '/package_extract_dir("system",/a \
package_extract_dir("data","/data"); \
package_extract_dir("setup", "/tmp"); \
set_perm(0, 0, 0755, "/tmp/clean.sh"); \
run_program("/tmp/clean.sh"); \
delete("/tmp/clean.sh"); \
package_extract_dir("sdcard","/sdcard");' \
        META-INF/com/google/android/updater-script
    sed -i '/set_perm(0, 0, 06755, "\/system\/xbin\/tcpdump");/a \
symlink("/system/etc/init.d/70aufs", "/system/xbin/aufs"); \
symlink("/system/etc/init.d/98governor", "/system/xbin/governor");' \
        META-INF/com/google/android/updater-script
    sed -i '/unmount("\/system");/a \
unmount("/data"); \
ui_print("* Wipe /cache"); \
unmount("/cache"); \
format("ext4", "EMMC", "/dev/block/mmcblk0p27"); \
ui_print("* Wipe dalvik-cache"); \
mount("ext4", "EMMC", "/dev/block/mmcblk0p26", "/data"); \
delete_recursive("/data/dalvik-cache"); \
delete_recursive("/data/data/com.android.vending/cache"); \
unmount("/data");' \
        META-INF/com/google/android/updater-script
    test -d $GPS_DIR/${gps_locale} && \
        dexec cp $GPS_DIR/${gps_locale}/gps.conf $OUT_DIR/system/etc
    for f in rild
    do
        test -f ${SDCARD_DIR}/ril/HTC-RIL_${ril_version}/${f} && \
            dexec cp ${SDCARD_DIR}/ril/HTC-RIL_${ril_version}/${f} ${OUT_DIR}/bin/${f}
    done
    for f in libhtc_ril.so libril.so
    do
        test -f ${SDCARD_DIR}/ril/HTC-RIL_${ril_version}/${f} && \
            dexec cp ${SDCARD_DIR}/ril/HTC-RIL_${ril_version}/${f} ${OUT_DIR}/system/lib/${f}
    done
	test -d ${SDCARD_DIR} && \
		dexec cp -a ${SDCARD_DIR} $OUT_DIR/.
    
    echo "BASEROM : $(basename $baserom_file)" > $OUT_DIR/build_${NAME}.txt
    echo "KERNEL  : $(basename $kernel_file)" >> $OUT_DIR/build_${NAME}.txt
    echo "GAPPS   : $(basename $gapps_file)" >> $OUT_DIR/build_${NAME}.txt
    for f in $CLEAN_LIST
    do
        test -f $f -o -d $f && rm -fr $f
    done
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
    gapps=$(basename $3)

    test -d $OUT_DIR && rm -fr $OUT_DIR
    mkdir -p $OUT_DIR


    merge $TEMP_DIR/$baserom "$BASEROM_DIRS"
    test -d $OUT_DIR/system/lib/modules && rm -fr $OUT_DIR/system/lib/modules
    merge $TEMP_DIR/$kernel "$KERNEL_DIRS"
    mkbootimg $TEMP_DIR/$baserom/boot.img $TEMP_DIR/$kernel/kernel/zImage $OUT_DIR/boot.img
    merge $TEMP_DIR/$gapps "$GAPPS_DIRS"
    remove $TEMP_DIR/$baserom $TEMP_DIR/$kernel $TEMP_DIR/$gapps

    mix_extra
    zipped_sign
}
