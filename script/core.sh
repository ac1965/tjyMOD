#! /usr/bin/env bash

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
    echo -ne "${FIRST_COLOR}>${WARN_2ND_COLOR}>${WARN_3RD_COLOR}> ${NORMAL}${@}"
}

dexec () {
    local CMD="$@"

    echo "Exec:$CMD" >> $LOG
    eval $CMD >> $LOG 2>&1 || die "Die:$CMD"
}

usage () {
    if [ -d ${RIL_DIR} ]; then
	    local rils=$(ls ${RIL_DIR} | sed 's/HTC-RIL_//g')
    	local rils_ver=$(for ver in $rils; do printf " %-9s" $ver; done)
    else
    	local rils_ver="NONE"
    fi
    if [ -d ${MARKET_DIR} ]; then
    	local markets=$(ls ${MARKET_DIR} | sed 's/Vending-//g' | sed 's/\.apk//g')
    	local markets_ver=$(for ver in $markets; do printf " %-9s" $ver; done)
    else
    	local markets_ver="NONE"
    fi

    cat <<EOF
Usage:
   $myname (-v) all|clean [(--kernel KERNEL_FILE) (--baserom ROM_FILE)]
                           [--enable-local-extra-file FILE | --disable-extra]
                           [(--gapps GAPS_FILE)]
                           [(--ril-version VER) (--market-version VER) (--gps-locale LOCALE)]

   $myname (-v) clean

       RILS:   ${rils_ver}
       MARKETS:${markets_ver}
EOF
    exit
}

unpack () {
    ewarn "unpack $(readlink -f $1)"
    test -d $TEMP_DIR || install -d $TEMP_DIR
    out="$(basename $1)"
    dexec unzip -x $1 -d $TEMP_DIR/$out >> $LOG 2>&1
}

download () {
    local url=$1
    local target=$(basename $url)
    local downdir=$(readlink -f $DOWN_DIR)

    echo -ne ": ${INFO_3RD_COLOR}Download${NORMAL} "
    dexec echo "download ${target} from ${url}"
    wget $url -q -O ${downdir}/${target}
    return $?
}

pretty_download () {
    local url=$1
    local target=$(basename $url)
    local downdir=$(readlink -f $DOWN_DIR)

    cd $DOWN_DIR
    if [ -f ${DOWN_DIR}/${target}.sum ]; then
        md5sum --status --check ${target}.sum
        case "$?" in
            0)
                echo -ne ": ${FIRST_COLOR}Exist${NORMAL} \n";;
            *)
                download $url
                md5sum $target > ${target}.sum
                echo -ne "\n";;
        esac
    else
        download $url
        md5sum $target > ${target}.sum
        echo -ne  "\n"
    fi
    cd - > /dev/null
}

download_apps () {
    local url=$1
    local dest=$2
    local target=$(basename $url)

    ewarn_n  "Get: $target"
    cd $DOWN_DIR

    test $local_extra = 1 && if [ -f ${target}.sum ]; then
	    pkgsum=$(grep $target ${target}.sum | cut -d' ' -f1)
    fi || pkgsum=$(grep $target packages.list | cut -d' ' -f1)
    if [ -f $target ]; then
        targetsum=$(md5sum $target | cut -d' ' -f1)
        if [ x"${pkgsum}" = x"${targetsum}" ]; then
            echo -ne " : ${FIRST_COLOR}Exist${NORMAL} "
        else
            download $url || die "Download Error"
            test $local_extra = 1 && if [ ! -f ${target}.sum ]; then
                md5sum $target > ${target}.sum 
            fi
        fi
    else
        download $url || die "Download Error"
        test $local_extra = 1 && if [ ! -f ${target}.sum ]; then
            md5sum $target > ${target}.sum 
        fi
    fi

    echo -ne ": Copy $dest\n"
    if [ "${dest}" = "/system/app" ]; then
        test -d ${OUT_DIR}/system/app || install -d ${OUT_DIR}/system/app
        cp $target ${OUT_DIR}/system/app/
    elif [ "${dest}" = "/data/app" ]; then
        test -d ${OUT_DIR}/data/app || install -d ${OUT_DIR}/data/app
        cp $target ${OUT_DIR}/data/app/
    else
	    ewarn "${dest}"
    fi
    cd - > /dev/null
}

pretty_get () {
    local fname=$1
    local target=$(basename $fname)

    ewarn_n  "Get: $target"
    url="${default_url}/${target}"
    if [ -f $fname ]; then
        echo -ne "\n"
        unpack $fname
    else
        pretty_download $url
        unpack ${DOWN_DIR}/${target}
    fi
}

merge () {
    local target=$1
    local dirs="$2"

    for t in $target
    do
        ewarn_n "Reconstrunction: ${REMARK_COLOR}$(basename $t)${NORMAL} ${FIRST_COLOR}[$dirs]${NORMAL}\n * "
        (
            cd $t
            for d in $dirs
            do
                if test -d $d; then
                    echo -ne "${REMARK_COLOR}$(basename $d)${NORMAL} "
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
        ewarn "Remove:$(readlink -f ${t})"
	    rm -fr $t
    done
}

pretty_fix () {
    local suffix=$1

    cd $OUT_DIR
    for f in $(find . -name "*.${suffix}")
    do
        test -f $f && (
            name=$(basename $f .${suffix})
            tdir=$(dirname $f)
            echo -ne "${REMARK_COLOR}$name${NORMAL} "
            if [ x"$suffix" = x"prepend" ]; then
                cat $f ${tdir}/${name} > ${name}.new
            else
                cat ${tdir}/${name} $f > ${name}.new
            fi
            mv ${name}.new ${tdir}/${name}
        )
        rm -f $f
    done
    cd - > /dev/null
    echo -ne "\n"
}

pretty_extrat () {
    local WDIR=$1
    
    ewarn_n "Mixup: $(readlink -f $WDIR)\n * "

    cd $WDIR
    for d in $DIRS
    do
        if test -d $d; then
            echo -ne "${REMARK_COLOR}$(basename $d)${NORMAL} "
            tar cf - $d | (cd $OUT_DIR; tar xvf -) >> $LOG 2>&1
        fi
    done
    cd - > /dev/null
    echo -ne "\n"
}

mix_extra () {
    pretty_extrat $BASE_DIR

    ewarn_n "PRE: $(readlink -f $OUT_DIR)\n * "
    pretty_fix "prepend"
    ewarn_n "APPEND: $(readlink -f $OUT_DIR)\n * "
    pretty_fix "append"

    for t in $base_list
	do
    	download_apps $t "/system/app"
	done

    if [ $disable_extra = 0 ]; then
        test $local_extra = 1 && if [ -f $local_extra_file ]; then
    	    ewarn "Select: $(basename $local_extra_file)"
    	    source $local_extra_file
        fi
        for t in $extra_list
        do
            download_apps $t "/data/app"
            echo $t >> $EXTR_DIR/extra.list
        done
    fi

    $EXTR_DIR/build-clean.sh
    pretty_extrat $EXTR_DIR
}

mkbootimg () {
    local OLDIMG=$1
    local ZIMAGE=$2
    local BOOT=$3
    local T="$TEMP_DIR/mkbootimg"

    test -d $T || install -d $T
    dexec dd if=$OLDIMG of=$TEMP_DIR/boot.img
    dexec $TOOLS_DIR/unpackbootimg -i $TEMP_DIR/boot.img -o $T
    dexec $TOOLS_DIR/mkbootimg --kernel $ZIMAGE \
	    --ramdisk $T/boot.img-ramdisk.gz \
        --cmdline $(cat $T/boot.img-cmdline) \
        --base $(cat $T/boot.img-base) \
        --output $BOOT
    rm -fr $T $TEMP_DIR/boot.img
}

zipped_sign () {
    local NAME=${PKGNAME}-${dt}
    test $disable_extra = 1 && NAME=${PKGNAME}-"no_extraapps"-${dt}
    test $local_extra = 1 && NAME=${PKGNAME}-"with_local_extraapps"-${dt}
    test $extra_only = 1 && NAME=${PKGNAME}-"extraapps"-${dt}
    local ZIPF="$(readlink -f $OUT_DIR/../${NAME}.zip)"
    local OUTF="$(readlink -f $OUT_DIR/../${NAME}.signed.zip)"

    local NAME=${PKGNAME}-${dt}

    test -f $ZIPF && rm -f $ZIPF

    ewarn_n "BUILD ROM: $(basename $OUTF)\n * "
    cd $OUT_DIR

    echo -ne "customize::"
    echo -ne " build.prop"
    sed -i 's/DD_VERSION/'${PKGNAME}_${dt}'/' system/build.prop

    cat $ART_DIR/logo.txt META-INF/com/google/android/updater-script > _u
    sed -i 's/DD_VERSION/'${PKGNAME}_${dt}'/' _u
    sed -i 's/DD_BASEROM/'$(echo $(basename ${baserom_file}) | \
	    sed 's/.signed.zip//' | sed 's/.zip//')'/' _u
    sed -i 's/DD_KERNEL/'$(echo $(basename ${kernel_file}) | \
	    sed 's/.signed.zip//' | sed 's/.zip//')'/' _u
    sed -i 's/DD_GAPPS/'$(echo $(basename ${gapps_file}) | \
	    sed 's/.signed.zip//' | sed 's/.zip//')'/' _u

    # RIL selected    
    if [ -d ${RIL_DIR}/HTC-RIL_${ril_version} ]; then
        echo -ne " RIL[${REMARK_COLOR}$ril_version${NORMAL}]"
        sed -i 's/RIL   : DEFAULT/RIL   : '$ril_version'/' _u
        for f in rild
        do
            test -f ${RIL_DIR}/HTC-RIL_${ril_version}/${f} && \
                dexec cp ${RIL_DIR}/HTC-RIL_${ril_version}/${f} bin/${f}
        done
        for f in libhtc_ril.so libril.so
        do
            test -f ${RIL_DIR}/HTC-RIL_${ril_version}/${f} && \
                dexec cp ${RIL_DIR}/HTC-RIL_${ril_version}/${f} system/lib/${f}
        done
    fi

    # Market selected
    if [ -f ${MARKET_DIR}/Vending-${market_version}.apk ]; then
        echo -ne " MARKET[${REMARK_COLOR}$market_version${NORMAL}]"
        sed -i 's/MARKET: DEFAULT/MARKET: '$market_version'/' _u
        dexec cp ${MARKET_DIR}/Vending-${market_version}.apk \
		    system/app/Vending.apk
    fi

    # Locale selected: /system/etc/gps.conf copy each countries
    test -z $gps_locale || (
        if [ -d $GPS_DIR/${gps_locale} ]; then
            echo -ne " Locale[${REMARK_COLOR}$gps_locale${NORMAL}]"
            sed -i 's/GPS   : DEFAULT/GPS   : '$gps_locale'/' _u
            dexec cp $GPS_DIR/${gps_locale}/gps.conf system/etc/
        fi
    )
	test -d ${SDCARD_DIR} && \
		dexec cp -a ${SDCARD_DIR} $OUT_DIR/.

    echo -ne " updater-script"
    sed -i '/show_progress(0.500000, 0);/a \
ui_print("* Format /system"); \' _u
    sed -i '/mount("ext4", "EMMC", "\/dev\/block\/mmcblk0p25",/a \
mount("ext4", "EMMC", "/dev/block/mmcblk0p26", "/data"); \
ui_print("* Extract ROM"); \
' _u
    sed -i '/package_extract_dir("system",/a \
package_extract_dir("data","/data"); \
package_extract_dir("setup", "/data/local/tmp"); \
set_perm(0, 0, 0755, "/data/local/tmp/clean.sh"); \
run_program("/data/local/tmp/clean.sh"); \
delete("/data/local/tmp/clean.sh"); \
package_extract_dir("sdcard","/sdcard"); \
' _u
    sed -i '/set_perm(0, 0, 06755, "\/system\/xbin\/tcpdump");/a \
symlink("/system/etc/init.d/70aufs", "/system/xbin/aufs"); \
symlink("/system/etc/init.d/98governor", "/system/xbin/governor"); \
' _u
    sed -i '/package_extract_file("boot.img",/a \
ui_print("* Write Kernel Image"); \
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
    echo "MARKET  : ${market_version}" >> $OUT_DIR/build_${NAME}.txt
    echo "GPS     : ${gps_locale}" >> $OUT_DIR/build_${NAME}.txt
    test $disable_extra = 1 && echo "EXTRA   : DISABLE" >> $OUT_DIR/build_${NAME}.txt
    test $local_extra = 1 && (
        echo "------" >> $OUT_DIR/build_${NAME}.txt
        echo "EXTRA   : LOCAL $local_extra_file" >> $OUT_DIR/build_${NAME}.txt
        echo "$extra_list" >> $OUT_DIR/build_${NAME}.txt
    )

    for f in $CLEAN_LIST
    do
        test -f $f -o -d $f && rm -fr $f
    done

    echo -ne " => zipped"
    dexec zip -r9 $ZIPF . >> $LOG 2>&1
    echo -ne " => sign-zipped${NORMAL}"
    dexec java -jar $TOOLS_DIR/signapk.jar \
	    $TOOLS_DIR/certification.pem \
	    $TOOLS_DIR/key.pk8 $ZIPF $OUTF && \
	    rm -f $ZIPF
    echo -ne "\n"
}

build () {
    local baserom=$(basename $1)
    local kernel=$(basename $2)
    local gapps=$(basename $3)

    test -d $OUT_DIR && rm -fr $OUT_DIR
    install -d $OUT_DIR
    test -x $EXTR_DIR/build-clean.sh || chmod +x $EXTR_DIR/build-clean.sh


    if [ $extra_only = 1 ]; then
	merge $TEMP_DIR/$baserom "$BASEROM_DIRS"
    	test -d $OUT_DIR/system/lib/modules && rm -fr $OUT_DIR/system/lib/modules
    	merge $TEMP_DIR/$kernel "$KERNEL_DIRS"
    	mkbootimg $TEMP_DIR/$baserom/boot.img \
		$TEMP_DIR/$kernel/kernel/zImage \
		$OUT_DIR/boot.img
    	merge $TEMP_DIR/$gapps "$GAPPS_DIRS"
    	remove $TEMP_DIR/$baserom $TEMP_DIR/$kernel $TEMP_DIR/$gapps
    fi
    mix_extra

    zipped_sign
}
