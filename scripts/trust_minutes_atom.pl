# Portions Copyright (C) 2011-2012 Pasi Eronen.
#
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

my $base = 'https://trustee.ietf.org/documents/minutes/';

die "usage: trust_minutes_atom data-XXX data-YYY\n" unless (@ARGV == 2);
my $input = $ARGV[1] . '/trust_minutes.html';
my $output = $ARGV[1] . '/trust_minutes_atom.xml';

my $atom = new MyAtomWriter();
$atom->feed
    (
     title => 'IETF Trust Meeting Minutes',
     link => $base,
     id => "tag:pasi\@people.nokia.net,2009:trust_minutes_atom",
     author => "IETF Trust"
     );


open(INPUT, "<:encoding(iso-8859-1)", $input) || die "$input: $!\n";
my $count = 0;
while ($_ = <INPUT>) {
    if (/<a href="(https:\/\/trustee.ietf.org\/wp-content\/uploads\/)([^"]+minutes[^"]+)">(.*?)<\/a>/i) {
        my ($prefix, $link, $date) = ($1, $2, $3);
        my $id = "tag:pasi\@people.nokia.net,2009:trust_minutes_atom,$link";
        $date =~ s/\s+/ /g;
        $atom->entry
            (
             title => "IETF Trust Minutes: $date",
             link => "$prefix$link",
             id => $id
             );
        last if (++$count > 20);
    }
}
close INPUT;

$atom->write_to_file($output) || die "$output: $!\n";

exit 0;
