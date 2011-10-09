#! /usr/bin/env bash

set -e

workdir="$(readlink -f $(dirname $0))"

. $workdir/core.sh || exit 1

giturl="git://github.com/ac1965/DD.git"
default_kernel="lordmodUEv7.2-CFS-b13.zip"
default_baserom="cm_ace_full-220.zip"

dt=$(date +%Y%m%d)
verbose=0
logf=$workdir/../$(basename $0 .sh)_$dt.log
kernel_file=
baserom_file=

usage () {
    cat <<EOF
Usage:
   $PKGNAME (-v) all (--kernel KERNEL_FILE) (--baserom ROM_FILE)
   $PKGNAME (-v) clean

EOF
    exit
}

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
        --help|-help|-h) usage;;
        *=*) optarg=$(echo $option | cut -d "=" -f 2,3);;
        *)   optarg=yes;;
    esac

    case $option in
        --verbose|-verbose|-v)
            LOG=/dev/stdout
            verbose=1;;
        --kernel|-kernel|-k)
            prev=kernel_file;;
        --kernel=*|-kernel=*|-k=*)
            # kernel_file=$optarg;;
            die "argument miss: $optarg";;
        --baserom|-baserom|-b|-r)
            prev=baserom_file;;
        --baserom=*|-baserom=*|-b=*|-r=*)
            # baserom_file=$optarg;;
            die "argument miss: $optarg";;
    esac
done

test $verbose = 0 && LOG=$logf
test -z $kernel_file && kernel_file=$default_kernel
test -z $baserom_file && baserom_file=$default_baserom
test -f $logf && mv $logf $logf.prev
echo "LOG:$LOG"

for option
do
    case "$option" in
        all)
            einfo "Automatic Build ROM"
            cleanup && get_baserom $baserom_file && get_kernel $kernel_file && build $baserom_file $kernel_file
            ;;
        clean)
            einfo "Cleaning"
            all_cleanup
            ;;
    esac
done
