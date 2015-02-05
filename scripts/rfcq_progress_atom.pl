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
use XML::XPath;

my $TAG_BASE = "tag:pasi\@people.nokia.net,2007:rfcq_progress_atom";
my $BASE_URL = "http://www.rfc-editor.org/queue.html";

die "usage: rfcq_progress_atom data/XXX data/YYY\n" unless (@ARGV == 2);
my $older = $ARGV[0] . '/rfc_queue.xml';
my $newer = $ARGV[1] . '/rfc_queue.xml';
my $output = $ARGV[1] . '/rfcq_progress_atom.xml';

sub read_queue_states {
    my ($filename) = @_;
    my $doc = XML::XPath->new(filename => $filename);
    my $nodeset = $doc->find('/rfc-editor-queue/section/entry');
    my %data = ();
    foreach my $entry ($nodeset->get_nodelist) {
        my $draft = $entry->findvalue('draft');
        $draft =~ s/\s+//gs;
	$draft =~ s/-\d\d(\.[a-z]+)?$//;
        my @states = ();
        foreach my $s ($entry->find('./state')->get_nodelist) {
            push @states, $s->string_value();
        }
	$data{$draft} = join(",", @states);
    }
    return %data;
}

my %old = read_queue_states($older);
my %new = read_queue_states($newer);

my $atom = new MyAtomWriter();
$atom->feed
    (
     title => 'RFC Editor Progress',
     link => $TAG_BASE,
     id => $TAG_BASE,
     author => "?"
    );

foreach my $doc (sort keys %new) {
  my $old_states = $old{$doc}; 
  my $new_states = $new{$doc}; 
  my $summary = "";
  if (($old_states !~ /AUTH48/) && ($new_states =~ /AUTH48/)) {
    $summary .= "\273 AUTH48";
  }
  if (($old_states !~ /ISR/) && ($new_states =~ /ISR/)) {
    $summary .= "\273 ISR";
  }
  if ($summary) {
      $atom->entry(
          title => $doc,
	  link => "$BASE_URL#$doc",
	  id => "$TAG_BASE,$doc",
          summary => $summary
      );
    }
}

$atom->write_to_file($output) || die "$output: $!\n";
exit 0;
