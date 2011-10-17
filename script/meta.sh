#! /usr/bin/env bash

set -e

workdir="$(readlink -f $(dirname $0))"
dt=$(date +%Y%m%d%H%M)

. $workdir/core.sh || exit 1

verbose=0
kernel_file=
baserom_file=
logf=${O}/$(basename $0 .sh)_$dt.log

einfo "Android ROM Build v${VERSION} - ${giturl}"

test "$#" = 0 && usage

prev=
for option
do
    if test -n "$prev"; then
        eval $prev=\$option
        prev=
        continue
    fi

    case $option in
        *=*) optarg=$(echo $option | cut -d'=' -f2,3);;
        *)   optarg=yes;;
    esac

    case $option in
        --kernel|-kernel|-k)
            prev=kernel_file;;
        --kernel=*|-kernel=*|-k=*)
            kernel_file=$optarg;;
        --baserom|-baserom|-b|-r)
            prev=baserom_file;;
        --baserom=*|-baserom=*|-b=*|-r=*)
            baserom_file=$optarg;;
        --gapps|-gapps|-g)
            prev=gapps_file;;
        --gapps=*|-gapps=*|-g-*)
            gapps_file=$optarg;;
        --help|-help|-h) usage;;
        -*) die "recognized option: $optarg";;
    esac

    for var in kernel_file baserom_file gapps_file
    do
        eval val=$`echo $var`
        test -z $val && continue
        abspath=$(readlink -f $(echo $val))
        case $abspath in
            [\\/$]* | ?:[\\/]*) eval $var=\$abspath;;
            *) die "expected an absolute name for $var:$val";;
        esac
    done
done

test $verbose = 0 && LOG=$logf
test -z $kernel_file && kernel_file=$default_kernel
test -z $baserom_file && baserom_file=$default_baserom
test -z $gapps_file && gapps_file=$default_gapps
test -d $O || install -d $O
test -f $logf && mv $logf $logf.prev

for option
do
    case "$option" in
        --verbose|-verbose|-v)
            LOG=/dev/stdout
            verbose=1;;
        all)
            einfo "Automatic Build ROM"
            echo -e "\t\033[1;30mLOG:$LOG\033[0m"
            remove $TEMP_DIR $OUT_DIR && \
                pretty_get $baserom_file "baserom" && \
                pretty_get $kernel_file "kernel" && \
                pretty_get $gapps_file "gapps" && \
                build $baserom_file $kernel_file $gapps_file
            ;;
        clean)
            einfo "Cleaning"
            remove $TEMP_DIR $OUT_DIR
            ;;
    esac
done
