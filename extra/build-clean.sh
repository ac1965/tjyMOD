#! /bin/bash

wdir=$(readlink -f $(dirname $0))

echo 'rm /system/lib/modules/*' > ${wdir}/setup/clean.sh
for f in $(cat base.list)
do
	name=$(basename $f .apk)
	echo 'rm /system/app/'$name'*.apk'
done >> ${wdir}/setup/clean.sh

for f in $(cat extra.list)
do
	name=$(basename $f .apk)
	echo 'rm /data/app/'$name'*.apk'
done >> ${wdir}/setup/clean.sh
