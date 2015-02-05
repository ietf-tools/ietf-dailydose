#!/bin/sh
DST=$HOME/public_html
DSTURL="http://merlot.tools.ietf.org/~pasi/"
DIR=/www/tools.ietf.org/dailydose/

cd $DIR
date=`date "+%Y-%m-%d"`
file=dailydose-backup-$date.tar
echo Creating $DST/$file

rm -f $DST/$file $DST/$file.gz
(echo articles && echo dailydose-trunk && find . -maxdepth 1 -type l -or -type f) | xargs tar rvf $DST/$file
gzip $DST/$file

echo Backup done, URL:
echo $DSTURL$file.gz

