#! /usr/bin/env bash

set -e
export LANG=C

workdir="$(readlink -f $(dirname $0))"
dt=$(date +%Y%m%d)

. $workdir/setting.sh || exit 1
. $workdir/core.sh || exit 1

verbose=0
kernel_file=
baserom_file=
logf=${O}/${PKGNAME}_$dt.log

einfo "Android ROM Build v${VERSION} - ${giturl}"

test "$#" = 0 && usage

prev=
gps_locale=
ril_version=
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
        --baserom|-baserom|-b)
            prev=baserom_file;;
        --baserom=*|-baserom=*|-b=*)
            baserom_file=$optarg;;
        --gapps|-gapps|-g)
            prev=gapps_file;;
        --gapps=*|-gapps=*|-g-*)
            gapps_file=$optarg;;
        --gps-locale|-gps-locale|-l)
            prev=gps_locale;;
        --gps-locale=*|-gps-locale=*|-l=*)
            gps_locale=$optarg;;
        --ril-version|-ril|-r)
            prev=ril_version;;
        --ril-version=*|-ril=*|-r=*)
            ril_version=$optarg;;
        --help|-help|-h) usage;;
        --verbose|-verbose|-v)
            LOG=/dev/sdtout; verbose=1;;
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
        all)
            einfo "Automatic Build ROM"
            echo -e "\t${FIRST_COLOR}LOG:$LOG${NORMAL}"
            remove $TEMP_DIR $OUT_DIR && \
                pretty_get $(readlink -f $baserom_file) && \
                pretty_get $(readlink -f $kernel_file) && \
                pretty_get $(readlink -f $gapps_file) && \
                build $baserom_file $kernel_file $gapps_file
            ;;
        clean)
            einfo "Cleaning"
            remove $TEMP_DIR $O
            ;;
    esac
done
