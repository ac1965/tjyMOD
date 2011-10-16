#!/system/xbin/bash

#--
rfs=/sdcard/gentoo-rfs.4g
pfs=/sdcard/portage.1g
#--

is_mod () {
	lsmod | grep -q $2
	ret="$?"
	case "$1" in
	mount)
		test $ret -eq 1 && modprobe $2;;
	umount)
		test $ret -eq 0 && rmmod $2;;
	esac
	sleep 2
}

die () {
    echo $1
    exit 1
}

help () {
    echo 'usage:' $(basename $0) '[ mount | umount ]'
    exit 0
}

is_mount () {
    mount | grep -q $2
	res="$?"
	case "$1" in
	mount)
		test $res -eq 1 && echo -n " [$2]";;
	umount)
		test $res -eq 0 && echo -n " [$2]";;
	esac
    return $res
}

if [ $# -ne 1 ]; then
    help
fi

test -d /data/gentoo || mkdir /data/gentoo

case "$1" in
mount)
	echo "$1:"
	for n in 0 1 2 3 4 5 6 7
	do
	    test -b /dev/loop${n} || mknod /dev/loop${n} b 7 ${n}
	done
	for fs in ${rfs} ${pfs}
	do
	    test -f ${fs} && losetup $(losetup -f) ${fs} || die "${fs} can not do loopback"
	done
	is_mount $1 '/data/gentoo' || mount $(losetup | grep gentoo-rfs | cut -d':' -f1) /data/gentoo
	is_mount $1 '/data/gentoo/proc' || mount -t proc none /data/gentoo/proc
	is_mount $1 '/data/gentoo/dev' || mount -o rbind /dev /data/gentoo/dev
	is_mount $1 '/data/portage' || (
	    is_mod $1 reiserfs
	    test -d /data/portage || mkdir /data/portage
	    test -d /data/gentoo/usr/portage || mkdir /data/gentoo/usr/portage
	    mount $(losetup | grep portage | cut -d':' -f1) /data/portage && \
	    	is_mount $1 '/data/gentoo/usr/portage' || \
			mount -o bind /data/portage /data/gentoo/usr/portage
	)
	is_mount $1 '/mnt/sdcard' && (
	    test -d /data/gentoo/mnt/sdcard || install -d /data/gentoo/mnt/sdcard
	    is_mount $1 '/data/gentoo/mnt/sdcard' || mount -o rbind /mnt/sdcard /data/gentoo/mnt/sdcard
	)
	cp -L /etc/resolv.conf /data/gentoo/etc/resolv.conf
	test -L /data/gentoo/system || (cd /data/gentoo; ln -s . system)
	echo " :-)"
	;;
umount)
	echo "$1:"
	is_mount $1 '/data/gentoo/usr/portage' && umount /data/gentoo/usr/portage
	is_mount $1 '/data/portage' && umount /data/portage
	is_mount $1 '/data/gentoo/mnt/sdcard' && umount -l /data/gentoo/mnt/sdcard
	is_mount $1 '/data/gentoo/dev' && umount -l /data/gentoo/dev
	is_mount $1 '/data/gentoo/proc' && umount /data/gentoo/proc
	is_mount $1 '/data/gentoo' && umount /data/gentoo
	is_mod $1 reiserfs
	loops=$(losetup | egrep 'gentoo|portage' | cut -d':' -f1)
	for dev in $loops
	do
	    losetup -d $dev
	done
	echo " :-)"
	;;
*)
	echo invalid argument : $1
	help;;
esac
