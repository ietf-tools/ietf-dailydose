#!/bin/bash
cd /www/tools.ietf.org/dailydose/

echo "Setting up symlinks and structure in $(pwd)"
ln -sf dailydose-current/static/* .
ln -sf dailydose-current/admin .
mkdir -p articles
touch articles/schedule

if [ ! -f latest_issue.txt ]; then
  echo Creating latest_issue.txt/html
  echo 9000 > latest_issue.txt
  echo "<!--#set var=\"latest_issue\" value=\"9000\" -->" > latest_issue.html
fi

if [ -f data/previous.txt ]; then
  echo "Directory $(pwd)/data already exists, not downloading"
else
  echo "Downloading $(pwd)/data from tools.ietf.org (two latest versions only)"
  versions=$(wget --no-verbose --output-document - https://durif.tools.ietf.org/dailydose/data/ | perl -ne 'if (/href=\"([0-9]+)/) { print $1, "\n"; }' | sort | tail -2)
  for version in $versions; do
    wget --recursive --no-parent --level=1 --no-clobber --no-host-directories --directory-prefix=data --cut-dirs=2 --no-verbose https://durif.tools.ietf.org/dailydose/data/$version/
    echo $version > data/previous.txt
  done
fi

echo "Starting Apache (with logs going to this terminal)"
apachectl -X &

echo "Go ahead!"
exec "$@"
