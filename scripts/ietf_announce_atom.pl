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


use strict;
use MyAtomWriter;

sub unquote {
    my ($s) = @_;
    $s =~ s/&lt;/</g;
    $s =~ s/&gt;/>/g;
    $s =~ s/&quot;/"/g;
    $s =~ s/&#39;/'/g;
    $s =~ s/&#x27;/'/g;
    $s =~ s/&apos;/'/g;
    $s =~ s/&amp;/&/g;
    return $s;
}

my $base1 = "https://mailarchive.ietf.org";
my $base2 = $base1 . "/arch/browse/ietf-announce/";

die "usage: ietf_announce_atom data-XXX data-YYY\n" unless (@ARGV == 2);
my $input = $ARGV[1] . '/ietf-announce-index.html';
my $output1 = $ARGV[1] . '/ietf_announce_nonrfc_atom.xml';
my $output2 = $ARGV[1] . '/ietf_announce_rfc_atom.xml';

my $atom_nonrfc = new MyAtomWriter();
$atom_nonrfc->feed
    (
     title => 'IETF-Announce List (except RFCs)',
     link => $base2,
     id => "tag:pasi\@people.nokia.net,2007:ietf_announce_nonrfc_atom",
     author => "?"
     );
my $atom_rfc = new MyAtomWriter();
$atom_rfc->feed
    (
     title => 'IETF-Announce List (RFCs only)',
     link => $base2,
     id => "tag:pasi\@people.nokia.net,2007:ietf_announce_rfc_atom",
     author => "?"
     );

open(INPUT, "<:utf8", $input) || die "$input: $!\n";
while ($_ = <INPUT>) {
    if (/href="(\/arch\/msg\/.*?)">(.*?)<\/a>/i) {
	my ($link, $title) = ($1, $2);
	$title =~ s/\s+/ /g;
	my $id = "tag:pasi\@people.nokia.net,2005:ietf_announce_rss,$link";
	my $atom_feed;
	if ($title =~ /^RFC \d+ on /) {
	    $atom_feed = $atom_rfc;
	} else {
	    $atom_feed = $atom_nonrfc;
	}
	$atom_feed->entry
	    (
	     title => unquote($title),
	     author => "",
	     link => ($base1 . $link),
	     id => $id
	     );
    }     
}
close INPUT;

$atom_nonrfc->write_to_file($output1) || die "$output1: $!\n";
$atom_rfc->write_to_file($output2) || die "$output2: $!\n";

exit 0;


