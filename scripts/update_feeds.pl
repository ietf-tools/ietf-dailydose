# Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved. Contact: Pasi Eronen <pasi.eronen@nokia.com>
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

#
# Finds 20 latest issues, reads their titles, 
# and outputs Atom and RSS feeds.
#
# Known limitations:
# - Feed contains only links, not actual content.
# - Update date comes from just stat().
#
use strict;
use MyRSSWriter;
use MyAtomWriter;

die "usage: update_feeds directory base-url\n" unless (@ARGV == 2);

my $dir = $ARGV[0];
my $BASE = $ARGV[1];
my $file1 = "$dir/dailydose_rss.xml";
my $file2 = "$dir/dailydose_atom.xml";

# Read latest issue number

my $file = "$dir/latest_issue.txt";
open(IN, $file) || die "$file: $!\n";
my $latest_issue = int(<IN>);
close IN;

# Read titles/dates for latest 20 issues

my %title;
my %updated;
for (my $issue = $latest_issue, my $count = 0; 
     ($issue > 0) && ($count < 20); 
     $issue--, $count++) {

    my $file = "$dir/$issue.html";
    open(IN, "<:utf8", $file) || die "$file: $!\n";
    while ($_ = <IN>) {
	if (/<!-- DATE=(\S+) (\d+)/) {
	    $title{$issue} = "The Daily Dose of IETF - Issue $issue - $1";
	    $updated{$issue} = $2;
	    last;
	}
    }
    close IN;
    if (!exists $title{$issue}) {
	die "update_feeds: cannot find title for $issue\n";
    }
}

# Create feeds

my $rss = new MyRSSWriter();
my $atom = new MyAtomWriter();
$rss->channel
    (
     title => 'The Daily Dose of IETF',
     link => $BASE,
     description => 'The Daily Dose of IETF'
     );
$atom->feed
    (
     title => 'The Daily Dose of IETF',
     link => $BASE,
     id => $BASE,
     self => $BASE."dailydose_atom.xml",
     author => 'Daily Dose'
     );

foreach my $issue (sort {$::b <=> $::a} keys %title) {
    $rss->add_item(title => $title{$issue},
		   guid => "$BASE$issue.html",
		   link => "$BASE$issue.html",
		   pubDate => $updated{$issue});
    $atom->entry(title => $title{$issue},
		 link => "$BASE$issue.html",
		 id => "$BASE$issue.html",
		 updated => $updated{$issue});
}
$rss->write_to_file($file1) || die "$file1: $!\n";
$atom->write_to_file($file2) || die "$file2: $!\n";

exit 0;
