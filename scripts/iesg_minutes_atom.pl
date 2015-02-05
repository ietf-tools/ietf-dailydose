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

my $base = 'http://www.ietf.org/iesg/minutes';

die "usage: iesg_minutes_atom data-XXX data-YYY\n" unless (@ARGV == 2);
my $input1 = $ARGV[1] . '/iesg_minutes1.html';
my $input2 = $ARGV[1] . '/iesg_minutes2.html';
my $output_official = $ARGV[1] . '/iesg_minutes_atom.xml';
my $output_narrative = $ARGV[1] . '/iesg_narrative_atom.xml';

my $atom_official = new MyAtomWriter();
$atom_official->feed
    (
     title => 'IESG Teleconference Official Minutes',
     link => $base,
     id => "tag:pasi\@people.nokia.net,2009:iesg_minutes_atom:official",
     author => "IESG"
     );
my $atom_narrative = new MyAtomWriter();
$atom_narrative->feed
    (
     title => 'IESG Teleconference Narrative Minutes',
     link => $base,
     id => "tag:pasi\@people.nokia.net,2009:iesg_minutes_atom:narrative",
     author => "IESG"
     );

foreach my $input ($input2, $input1) {
    open(INPUT, "<:utf8", $input) || die "$input: $!\n";
    while ($_ = <INPUT>) {
	if (/ href="(minutes-)(\d\d\d\d)(-\d\d-\d\d)(\.\w+)"/i) {
	    my $link = "$base/$2/$1$2$3$4";
	    my $date = "$2$3";
	    my $id = "tag:pasi\@people.nokia.net,2009:iesg_minutes_atom,official,$date";
	    $atom_official->entry
		(
		 title => "IESG Teleconference Official Minutes: $date",
		 link => $link,
		 id => $id, 
		 updated => $date
		);
	}
	if (/ href="(narrative-minutes-)(\d\d\d\d)(-\d\d-\d\d)(\.\w+)"/i) {
	    my $link = "$base/$2/$1$2$3$4";
	    my $date = "$2$3";
	    my $id = "tag:pasi\@people.nokia.net,2009:iesg_minutes_atom,narrative,$date";
	    $atom_narrative->entry
		(
		 title => "IESG Teleconference Narrative Minutes: $date",
		 link => $link,
		 id => $id, 
		 updated => $date
		);
	}
    }
    close INPUT;
}

$atom_official->write_to_file($output_official) || die "$output_official: $!\n";
$atom_narrative->write_to_file($output_narrative) || die "$output_narrative: $!\n";

exit 0;

