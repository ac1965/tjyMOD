#! /bin/bash

wdir=$(readlink -f $(dirname $0))

cd ${wdir}/../data/app
for f in *.apk
do
	name=$(basename $f .apk)
	echo 'rm -f /data/app/'$name'-*.apk'
done > ${wdir}/list
cd - >/dev/null
