#! /bin/bash

wdir=$(readlink -f $(dirname $0))
out='/sdcard/clean.log'

echo '#!/sbin/sh' > ${wdir}/setup/clean.sh
echo 'rm /system/lib/modules/*' >> ${wdir}/setup/clean.sh
echo "test -f $out && rm $out" >> ${wdir}/setup/clean.sh

for f in $(cat ${wdir}/extra.list)
do
	name=$(basename $f .apk)
	cmd='$(ls /data/app/'${name}'*.apk)'
    doll='$'
    cat <<EOF
for x in $cmd
do
   test -f ${doll}x && (
      rm -f ${doll}x && echo "remove: ${doll}x" || echo "not remove: ${doll}x"
   ) 
done >> $out
EOF
done >> ${wdir}/setup/clean.sh
