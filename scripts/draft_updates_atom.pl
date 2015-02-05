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
# Reads current & previous all_id.txt, outputs an Atom feed 
# containing changes 
#
# Example output:
# <entry>
#   <title>draft-hutzler-spamops</title>
#   <summary>Approved-announcement sent » RFC Ed Queue</summary>
#   <id>tag:pasi@people.nokia.net,2007:draft_updates_atom,
#       draft-hutzler-spamops-08,to-rfc-editor</id>
#   <link href="http://tools.ietf.org/id/draft-hutzler-spamops-08" />
#  <category term="to-rfc-editor" />
# </entry>
#
# The important parts are the title (draft name), summary (containing
# description of state change), and category, which is one of the following:
# - new: Draft didn't exist before
# - updated: Draft version has changed
# - expired: Draft has expired
# - revived: Draft is no longer expired
# - to-iesg: Draft now has proper tracker state "In IESG processing <*>"
# - to-rfc-editor: New state is "RFC Ed Queue"
# - iesg-progress: Changes within "In IESG processing <*>" 
# - rfc-published: Old state was "RFC Ed Queue", new state "RFC NNN"
# - other: anything else
#
# Known limitations:
# - Drafts can be listed twice (if e.g. both updated and state change)
# - ID elements are not unique across multiple runs of this script
#   (because e.g., there can be multiple separate events with category
#   "iesg-progress")
#
use strict;
use MyAtomWriter;

die "usage: draft_updates_atom old-data-dir new-data-dir\n" unless (@ARGV == 2);
my $older = $ARGV[0] . '/all_id.txt';
my $newer = $ARGV[1] . '/all_id.txt';
my $output = $ARGV[1] . '/draft_updates_atom.xml';

my $TAG_BASE = "tag:pasi\@people.nokia.net,2007:draft_updates_atom";

my (%versions, %statuses);

open(OLDER, "<:encoding(iso-8859-1)", $older) || die "$older: $!\n";
while ($_ = <OLDER>) {
    chop;
    next unless (my ($doc,$version,$date,$status) =
		 /^(draft-\S+)-(\d\d)\t(\S+)\t(.*)/);
    $status =~ s/\s+$//;
    $status =~ s/\t/ /g;
    $versions{$doc} = $version;
    $statuses{$doc} = $status;
}
close OLDER;

my $atom = new MyAtomWriter();
$atom->feed
    (
     title => 'Internet-Draft Updates',
     link => $TAG_BASE,
     id => $TAG_BASE,
     author => "?"
    );

open(NEWER, "<:encoding(iso-8859-1)", $newer) || die "$newer: $!\n";
while ($_ = <NEWER>) {
    chop;
    next unless (my ($doc,$version,$date,$status) =
		 /^(draft-\S+)-(\d\d)\t(\S+)\t(.*)/);
    if ($doc !~ /^[-0-9a-zA-Z+._]+$/) {
	print STDERR "draft_updates_atom: strange doc \"$doc\"\n";
	next;
    }
    $status =~ s/\s+$//;
    $status =~ s/\t/ /g;
    my $old_status = exists $statuses{$doc} ? $statuses{$doc} : "";
    my $link = "http://tools.ietf.org/id/$doc-$version";
    
    my $status_short = $status;
    if ($status =~ /ID Tracker state <(.*)>/i) {
	$status_short = $1;
    }
    my $old_status_short = $old_status;
    if ($old_status =~ /ID Tracker state <(.*)>/i) {
	$old_status_short = $1;
    }

    my $category = "";
    my $summary = "";
    if (!exists $versions{$doc}) {
	$category = "new";
	$summary = "New draft";
    } else {
	if ($versions{$doc} ne $version) {
	    $category = "updated";
	    $summary = "Updated draft";
	} 
	if ($status ne $old_status) {
	    $summary = "$old_status_short \273 $status_short";
	    if ($status eq "Expired") {
		$category = "expired";
	    } elsif (($old_status eq "Expired")  &&
		     ($status !~ /replaced by/i)) {
		$category = "revived";
	    }
	}
    }
    if ($category) {
	$atom->entry(
	    title => $doc,
	    link => $link,
	    id => "$TAG_BASE,$doc-$version,$category",
	    category => $category,
	    summary => $summary
	    );
    }
    
    next if ($status eq $old_status);
    $category = "";
    if (($status eq "Active") && 
	(($old_status eq "Expired") || !$old_status)) {
	# handled above
    } elsif (($status eq "Expired") && ($old_status eq "Active")) {
	# handled above
    } elsif (($status =~ /In IESG/) && ($old_status !~ /In IESG/)) {
	$category = "to-iesg";
    } elsif ($status =~ /<rfc ed queue>/i) {
	$category = "to-rfc-editor";
    } elsif (($status =~ /^\s*RFC\s+(\d+)\s*$/) &&
	     ($old_status =~ /<rfc ed queue>/i)) {
	$category = "rfc-published";
    } elsif (($status =~ /In IESG/) && ($old_status =~ /In IESG/)) {
	$category = "iesg-progress";
    } else {
	$category = "other";
    }
    if ($category) {
	$status_short =~ s/^Replaced replaced /Replaced /;
	$summary = "$old_status_short \273 $status_short";
	$summary =~ s/(.*)(::.*)? \273 \1::(.*)/$1$2 \273 ::$3/;
	$atom->entry(
	    title => $doc,
	    link => $link,
	    id => "$TAG_BASE,$doc-$version,$category",
	    category => $category,
	    summary => $summary
	    );
    }
}
close NEWER;

$atom->write_to_file($output) || die "$output: $!\n";

exit 0;
