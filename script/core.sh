#! /usr/bin/env bash

PKGNAME=tjyMOD
VERSION=0.3

# I hope to put site my KANG, kernel and ROM.
giturl="git://github.com/ac1965/tjyMOD.git"
default_url="http://tjy.sakura.ne.jp/pu/up/android"
default_kernel="update_2.6.35-BFS-WIP-AUFS_201110241151.zip"
default_baserom="update-cm-7.1.0-DesireHD-KANG_201110221353.signed.zip"
default_gapps="gapps-gb-20110930-237-signed.zip"

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
SDMOD_DIR="${SDCARD_DIR}/tjyMOD"
GPS_DIR="${SDMOD_DIR}/gpsconf"
RIL_DIR="${SDMOD_DIR}/ril"

# color escape
NORMAL="\033[0m"
FIRST_COLOR="\033[1;30m"
DIE_2ND_COLOR="\033[0;36m"
DIE_3RT_COLOR="\033[0;31m"
REMARK_COLOR="\033[1;31m"
INFO_2ND_COLOR="\033[0;36m"
INFO_3RD_COLOR="\033[1;36m"
WARN_2ND_COLOR="\033[0;33m"
WARN_3RD_COLOR="\033[1;33m"

die () {
    echo -e "${FIRST_COLOR}>${DIE_2ND_COLOR}>${DIE_3RD_COLOR}> ERROR:${NORMAL} ${@}" && exit 1
}

einfo () {
    echo -ne "${FIRST_COLOR}>${INFO_2ND_COLOR}>${INFO_3RD_COLOR}> ${NORMAL}${@}\n"
}

ewarn () {
    echo -ne "${FIRST_COLOR}>${WARN_2ND_COLOR}>${WARN_3RD_COLOR}> ${NORMAL}${@}\n"
}

ewarn_n () {
    echo -ne "${FIRST_COLOR}>${WARN_2ND_COLOR}>${WARN_3RD_COLOR}> ${NORMAL}${@}\n"
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

    ewarn "Download from $url"
    dexec wget $url -O $DOWN_DIR/$target >/dev/null 2>&1 || die "Can't download $target from $url"
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
    fname=$1

    target=$(basename $fname)   
    ewarn "Get $which: $target"
    url="${DEFAULT_URL}/${target}"
    test -f $fname && unpack $fname || pretty_download $target $url
}

merge () {
    target=$1
    dirs="$2"

    for t in $target
    do
        ewarn_n "Reconstrunction: ${REMARK}$(basename $t)${NORMAL} ${FIRST_COLOR}[$dirs]${NORMAL}\n * "
        (
            cd $t
            for d in $dirs
            do
                if test -d $d; then
                    echo -ne "${REMARK}$(basename $d)${NORMAL} "
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
            echo -ne "${REMARK}$name${NORMAL} "
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
            echo -ne "${REMARK}$(basename $d)${NORMAL} "
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

    echo -ne "customize::"
    echo -ne " build.prop"
    sed -i 's/DD_VERSION/'${PKGNAME}-v${VERSION}_${dt}'/' system/build.prop

    cat $ART_DIR/logo.txt META-INF/com/google/android/updater-script > _u
    sed -i 's/DD_VERSION/'${PKGNAME}-v${VERSION}_${dt}'/' _u
    sed -i 's/DD_BASEROM/'$(basename ${baserom_file})'/' _u
    sed -i 's/DD_KERNEL/'$(basename ${kernel_file})'/' _u
    sed -i 's/DD_GAPPS/'$(basename ${gapps_file})'/' _u

    # RIL selected    
    if [ -d ${RIL_DIR}/HTC-RIL_${ril_version} ]; then
        echo -ne " RIL[${REMARK}$ril_version]${NORMAL}]"
        sed -i 's/RIL: DEFAULT/RIL: '$ril_version'/' _u
        for f in rild
        do
            test -f ${RIL_DIR}/HTC-RIL_${ril_version}/${f} && \
                dexec cp ${RIL_DIR}/HTC-RIL_${ril_version}/${f} ${OUT_DIR}/bin/${f}
        done
        for f in libhtc_ril.so libril.so
        do
            test -f ${RIL_DIR}/HTC-RIL_${ril_version}/${f} && \
            dexec cp ${RIL_DIR}/HTC-RIL_${ril_version}/${f} ${OUT_DIR}/system/lib/${f}
        done
    fi

    # Locale selected: /system/etc/gps.conf copy each countries
    gps_locale="$(echo $gps_locale | tr '[a-z]' '[A-Z]')"
    if [ -d $GPS_DIR/${gps_locale} ]; then
        echo -ne " Locale[${REMARK}$gps_locale${NORMAL}]"
        sed -i 's/GPS: DEFAULT/GPS: '$gps_locale'/' _u
        dexec cp $GPS_DIR/${gps_locale}/gps.conf $OUT_DIR/system/etc
    fi
        
	test -d ${SDCARD_DIR} && \
		dexec cp -a ${SDCARD_DIR} $OUT_DIR/.

    echo -ne " updater-script"
    sed -i '/mount("ext4", "EMMC", "\/dev\/block\/mmcblk0p25",/a \
mount("ext4", "EMMC", "/dev/block/mmcblk0p26", "/data"); \
' _u
    sed -i '/package_extract_dir("system",/a \
package_extract_dir("data","/data"); \
package_extract_dir("setup", "/tmp"); \
set_perm(0, 0, 0755, "/tmp/clean.sh"); \
run_program("/tmp/clean.sh"); \
delete("/tmp/clean.sh"); \
package_extract_dir("sdcard","/sdcard"); \
' _u
    sed -i '/set_perm(0, 0, 06755, "\/system\/xbin\/tcpdump");/a \
symlink("/system/etc/init.d/70aufs", "/system/xbin/aufs"); \
symlink("/system/etc/init.d/98governor", "/system/xbin/governor"); \
' _u
    sed -i '/unmount("\/system");/a \
unmount("/data"); \
ui_print("* Wipe /cache"); \
unmount("/cache"); \
format("ext4", "EMMC", "/dev/block/mmcblk0p27"); \
ui_print("* Wipe dalvik-cache"); \
mount("ext4", "EMMC", "/dev/block/mmcblk0p26", "/data"); \
delete_recursive("/data/dalvik-cache"); \
delete_recursive("/data/data/com.android.vending/cache"); \
unmount("/data"); \
' _u

    mv _u META-INF/com/google/android/updater-script
    
    echo "BASEROM : $(basename $baserom_file)" > $OUT_DIR/build_${NAME}.txt
    echo "KERNEL  : $(basename $kernel_file)" >> $OUT_DIR/build_${NAME}.txt
    echo "GAPPS   : $(basename $gapps_file)" >> $OUT_DIR/build_${NAME}.txt
    echo "RIL     : ${ril_version}" >> $OUT_DIR/build_${NAME}.txt
    echo "GPS     : ${gps_locale}" >> $OUT_DIR/build_${NAME}.txt
    for f in $CLEAN_LIST
    do
        test -f $f -o -d $f && rm -fr $f
    done
    echo -ne " => zipped"
    dexec zip -r9 $ZIPF . >> $LOG 2>&1
    echo -ne " => sign-zipped${NORMAL}"
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
