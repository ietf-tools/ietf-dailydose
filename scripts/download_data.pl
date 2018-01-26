# Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved. Contact: Pasi Eronen6~ <pasi.eronen@nokia.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  * Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials provided
#    with the distribution.
#
#  * Neither the name of the Nokia Corporation and/or its
#    subsidiary(-ies) nor the names of its contributors may be used
#    to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use strict;

die "usage: download_data old-data-dir tmp-data-dir\n" unless (@ARGV == 2);

my $WGET = 'wget';
my $older = $ARGV[0];
my $newer = $ARGV[1];
my $MAX_ERRORS = 1;

my @files =
    (
     'ietf-announce-index.html',
     'http://www.ietf.org/mail-archive/web/ietf-announce/current/maillist.html',

     'all_id.txt',
     'http://www.ietf.org/internet-drafts/all_id.txt',

     '1id-abstracts.txt',
     'http://www.ietf.org/internet-drafts/1id-abstracts.txt',

     'ipr_disclosures_atom.xml',
     'https://datatracker.ietf.org/feed/ipr/',

     'liaisons.html',
     'https://datatracker.ietf.org/liaison/',

     'iesg_minutes1.html',
     'http://www.ietf.org/iesg/minutes/2017/',

     'iesg_minutes2.html',
     'http://www.ietf.org/iesg/minutes/2018/',

     'iabmins.html',
     'http://www.iab.org/documents/minutes/',

     'iaoc_minutes.html',
     'http://iaoc.ietf.org/minutes.html',

     'trust_minutes.html',
     'http://trustee.ietf.org/minutes.html',

     'rfc_queue.xml',
     'http://www.rfc-editor.org/queue.xml'
     );

my $error_count = 0;

while (@files > 0) {
    my $file = shift @files;
    my $url = shift @files;
    #print "download_data: Downloading $url\n";
    unlink "$newer/$file";
    my $ret = system("$WGET -nv --no-check-certificate -O $newer/$file $url");
    if ($ret != 0) {
	print "download_data: Error retrieving $url\n";
	if ($error_count++ < $MAX_ERRORS) {
	    print "download_data: Copying $older/$file\n";
	    $ret = system("cp $older/$file $newer/$file");
	    if ($ret != 0) {
		die "download_data: Copying failed\n";
	    }
	} else {
	    die "download_data: Failing, max. errors reached\n";
	}
    }
}

my $file = "$newer/download_data.txt";
open(OUT, ">$file") || die "$file: $!\n";
print OUT time(), "\n";
close OUT;

exit 0;
