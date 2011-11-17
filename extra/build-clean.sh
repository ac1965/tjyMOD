#! /bin/bash

wdir=$(readlink -f $(dirname $0))

echo 'rm /system/lib/modules/*' > ${wdir}/setup/clean.sh

for f in $(cat ${wdir}/extra.list)
do
	name=$(basename $f .apk)
	echo 'rm -f /data/app/'$name'*.apk'
done >> ${wdir}/setup/clean.sh
