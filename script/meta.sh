#! /usr/bin/env bash

set -e
export LANG=C

workdir="$(readlink -f $(dirname $0))"
dt=$(date +%Y%m%d)
myname=$(basename $0)

. $workdir/setting.sh || exit 1
. $workdir/core.sh || exit 1

kernel_file=
baserom_file=
local_extra_file=
logf=${O}/${PKGNAME}_$dt.log

einfo "Android ROM Build v${VERSION} - ${giturl}"

test "$#" = 0 && usage

prev=
verbose=0
local_extra=0
disable_extra=0
extra_only=0
gps_locale=
ril_version=
market_version=

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
        --disable-extra|-disable-extra)
            disable_extra=1;;
        --enable-local-extra-file|-enable-local-extra-file|-e)
            prev=local_extra_file;;
        --enable-local-extra-file=*|-enable-local-extra-file=*|-e=*)
            local_extra_file=$optarg;;
        --gps-locale|-gps-locale|-l)
            prev=gps_locale;;
        --gps-locale=*|-gps-locale=*|-l=*)
            gps_locale=$optarg;;
        --ril-version|-ril|-r)
            prev=ril_version;;
        --ril-version=*|-ril=*|-r=*)
            ril_version=$optarg;;
        --market-version|-market-version|-market|-m)
            prev=market_version;;
        --market-version=*|-market-version=*|-market=*|-m=*)
            market_version=$optarg;;
        --help|-help|-h) usage;;
        --verbose|-verbose|-v)
            LOG=/dev/stdout; verbose=1;;
        -*) die "recognized option: $optarg";;
    esac
done

test $verbose = 0 && LOG=$logf
test -z $kernel_file && kernel_file=$default_kernel
test -z $baserom_file && baserom_file=$default_baserom
test -z $gapps_file && gapps_file=$default_gapps
if [ ! -z $local_extra_file -a -f $local_extra_file ]; then
    test $disable_extra = 1 && die "conflict operand:--local-extra-file and --disable-extra"
	local_extra=1
	source $local_extra_file
	einfo "Using: $local_extra_file"
fi

test -d $O || install -d $O
test -d $DOWN_DIR || install -d $DOWN_DIR
test -f $logf && mv $logf $logf.prev
gps_locale=$(echo $gps_locale | tr '[a-z]' '[A-Z]')

for option
do
    case "$option" in
        all)
            test $disable_extra = 1 && einfo "Automatic Build ROM (Except /data)" \
				|| einfo "Automatic Build ROM"
            echo -e "\t${FIRST_COLOR}LOG:$LOG${NORMAL}"
            wget ${default_url}/packages.list -O ${DOWN_DIR}/packages.list >/dev/null 2>&1
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
