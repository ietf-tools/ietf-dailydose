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
# Reads an Atom feed + list of read IDs; writes an Atom
# feed with read entries removed, and updated list of read IDs.
#
# Also prints a warning if the Atom feed contains less than 2 entries.
#
# Known limitations:
# - Keeps track of only 1000 last seen IDs.
# - Relies on semi-undocumented features of XML::XPath to 
#   remove nodes (read entries) from the tree.
#
use strict; 
use XML::XPath;

die "usage: atom_unread.pl base old-data-dir new-data-dir\n" unless (@ARGV == 3);
my $older_read = $ARGV[1] . "/" . $ARGV[0] . "_read.txt";
my $newer_read = $ARGV[2] . "/" . $ARGV[0] . "_read.txt";
my $input = $ARGV[2] . "/" . $ARGV[0] . "_atom.xml";
my $output = $ARGV[2] . "/" . $ARGV[0] . "_unread.xml";

my @read_list = ();
my %read_hash = ();
open(OLDER_READ, $older_read) || die "$older_read: $!\n";
while ($_ = <OLDER_READ>) {
    s/\s+//gs;
    next unless ($_);
    $read_hash{$_} = 1;   
    push @read_list, $_;
}
close OLDER_READ;

my $doc = XML::XPath->new(filename => $input);
my $count = 0;

foreach my $entry ($doc->find('/feed/entry')->get_nodelist()) {
    my $id = $entry->findvalue('id');
    $id =~ s/\s+//gs;
    if (exists $read_hash{$id}) {
	$entry->getParentNode()->removeChild($entry);
    } else {
	push @read_list, $id;
    }
    $count++;
}

open(OUTPUT, ">:utf8", $output) || die "$output: $!\n";
print OUTPUT '<?xml version="1.0" encoding="utf-8"?>', "\n";
print OUTPUT $doc->findnodes_as_string('/'), "\n";
close OUTPUT;

open(NEWER_READ, ">$newer_read") || die "$newer_read: $!\n";
while (@read_list > 1000) {
    shift @read_list;
}
foreach $_ (@read_list) {
    print NEWER_READ $_, "\n";
}
close NEWER_READ;

if ($count < 2) {
    print "atom_unread: warning, only $count entries in $input\n";
}

0;
