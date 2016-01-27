#!/bin/sh
cd /www/tools.ietf.org/tools/dailydose
umask 002
export LC_ALL=en_US.UTF-8
sg tools "perl main.pl" 2>&1 | mail -s "dailydose output" eronenp@gmail.com henrik
