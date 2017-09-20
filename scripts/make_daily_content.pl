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
use Time::Local;
use POSIX qw(strftime);
use XML::XPath;
use IO::String;

die "usage: make_daily_content data/XXX data/YYY\n" unless (@ARGV == 2);
my $older = $ARGV[0];
my $newer = $ARGV[1];
my $output_left = $ARGV[1] . '/content_left.txt';
my $output_right = $ARGV[1] . '/content_right.txt';

# data from 1id-abstracts.txt
my (%titles, %authors, %abstracts);
# data from all_id.txt
my (%versions, %statuses);

sub quote {
    my ($s) = @_;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    $s =~ s/'/&#39;/g;
    $s =~ s/\273/&raquo;/g;
    return $s;
}

sub trim {
    my ($s) = @_;
    $s =~ s/\s+/ /gs;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return $s;
}


my $something_in_ul = 0;
my $ul_class = "";

sub print_start_ul {
    $something_in_ul = 0;
    $ul_class = $_[0];
}

sub print_end_ul {
    print "</ul>\n\n" if ($something_in_ul);
}

sub print_li {
    if (!$something_in_ul) {
	print ($ul_class ? "\n<ul class=\"$ul_class\">\n" : "\n<ul>\n");
	$something_in_ul = 1;
    }
    if ($_[0]) {
	print "  <li>", $_[0], "</li>\n";
    }
}

sub read_id_abstracts {
    my ($file) = @_;
    open(IN, "<:utf8", $file) || die "$file: $!\n";
    my ($tmp, $doc);
    $doc = '';
    while ($_ = <IN>) {
	chop;
	if ($_ =~ /^\s*$/) {
	    if ($tmp =~ /^  \"(.*)\",(.*)<(draft-\S*)-(\d\d)\.\S+>\s*$/) {
		my ($title, $authors) = ($1,$2);
		$doc = $3;
		$titles{$doc} = trim($title);
		$authors =~ s/[, ]+$//;
		$authors{$doc} = $authors;
	    } elsif ($tmp =~ /^      [A-Za-z]/) {
		if ($doc ne '') {
		    $abstracts{$doc} = trim($tmp);
		    $doc = '';
		}
	    }
	    $tmp = '';
	} else {
	    $tmp .= $_ . " ";
	}
    }
    close IN;
}

sub read_id_statuses {
    my $file = "$newer/all_id.txt";
    open(IN, "<:encoding(iso-8859-1)", $file) || die "$file: $!\n";
    while ($_ = <IN>) {
	next unless (my ($doc,$version,$date,$status) =
		     /^(draft-\S+)-(\d\d)\t(\S+)\t(.*)/);
	$versions{$doc} = $version;
	$status =~ s/^Replaced replaced /Replaced /;
	$statuses{$doc} = trim($status);
    }
    close IN;
}


my $next_id = 0;
sub print_doc {
    my ($doc, $text, $options) = @_;

    print_li();
    print "  <li onclick=\"javascript:toggleIdDetails('id$next_id')\" id=\"id${next_id}b\">";

    if (exists $titles{$doc}) {
	print "<span class=\"idtitle\">", quote($titles{$doc}), "</span> <span class=\"idname\">($doc)</span>", ($text ? ": " : ""), quote($text), "\n";
    } else {
	print "<span class=\"idtitle\">$doc</span>", ($text ? ": " : ""), quote($text), "\n";
    }

    print "<div id=\"id$next_id\" class=\"iddetails\" style=\"display:none\">\n";
    my $rfc_url = '';
    my $rfc_number;
    if ($statuses{$doc} =~ /\s*RFC\s+(\d+)\s*$/) {
	$rfc_number = $1;
        $rfc_url = "https://www.rfc-editor.org/rfc/rfc$rfc_number.txt";
	print "<p><a href=\"$rfc_url\">rfc$rfc_number.txt</a></p>\n";
    }
    if (exists $titles{$doc}) {
	print "<p>By ", quote($authors{$doc}), " &nbsp; ";
    } else {
	print "<p>No title available; expired document? &nbsp; ";
    }
    my $txt_url = "https://www.ietf.org/archive/id/$doc-$versions{$doc}.txt";
    my $html_url = "https://tools.ietf.org/html/$doc-$versions{$doc}.html";
    my $pdf_url = "https://tools.ietf.org/pdf/$doc-$versions{$doc}.pdf";
    print "<a href=\"$txt_url\" class=\"format\">TXT</a> <a href=\"$html_url\" class=\"format\">HTML</a> <a href=\"$pdf_url\" class=\"format\">PDF</a></p>\n";

    if (exists $abstracts{$doc}) {
	print "<p>Abstract: ", quote($abstracts{$doc}), "</p>\n";
    }
    my $idtools_str = IO::String->new;
    my $oldout = select $idtools_str;
    if ($options =~ /diff/ && ($versions{$doc} > 0)) {
	my $prev_version = sprintf "%02d", $versions{$doc}-1;
	my $diff_url = "https://tools.ietf.org/tools/rfcdiff/rfcdiff.pyht?url1=https://tools.ietf.org/id/$doc-$prev_version.txt&amp;url2=https://tools.ietf.org/id/$doc-$versions{$doc}.txt";
	print "<a href=\"$diff_url\">Diff from $prev_version to $versions{$doc} &raquo;</a><br />\n"; 
    } elsif ($rfc_url ne '') {
	my $diff_url = "https://tools.ietf.org/tools/rfcdiff/rfcdiff.pyht?url1=https://tools.ietf.org/id/$doc-$versions{$doc}.txt&amp;url2=$rfc_url";
	print "<a href=\"$diff_url\">Diff from $doc-$versions{$doc} to RFC $rfc_number &raquo;</a><br />\n";
    }
    
    if ($statuses{$doc} =~ /ID Tracker state <(.*)>/i) {
	print "State: ", quote($1), "<br />\n";
	print "<a href=\"https://datatracker.ietf.org/idtracker/$doc/\">ID Tracker &raquo;</a> &nbsp; \n";
	print "<a href=\"https://datatracker.ietf.org/feed/comments/$doc/\" class=\"format\">ATOM</a><br />\n";
    } elsif ($statuses{$doc} && ($statuses{$doc} ne "Active")) {
	print "State: ", quote($statuses{$doc}), "<br />\n";
    }
    if ($doc =~ /^draft-ietf-([^-]+)-/) {
	my $wg = $1;
	my $wgu = $wg;
	$wgu =~ tr/a-z/A-Z/;
	print "<a href=\"https://tools.ietf.org/wg/$wg/$doc\">Document details &raquo;</a><br />\n";
	print "<a href=\"https://tools.ietf.org/wg/$wg/\">$wgu WG &raquo;</a><br />\n";
    }
    if ($statuses{$doc} =~ /rfc ed/i) {
	print "<a href=\"https://www.rfc-editor.org/queue2.html#$doc\">RFC Editor Queue &raquo;</a><br />\n";
	#print "<a href=\"http://rtg.ietf.org/~fenner/ietf/rfc/hist.cgi?draft=$doc\">RFC Editor Queue History &raquo;</a><br />\n";
    }
    select $oldout;
    my $idtools_content = ${$idtools_str->string_ref};
    if ($idtools_content) {
	print "<div class=\"idtools\">\n<p>", 
	$idtools_content, 
	"</p>\n</div>\n";
    }

    print "</div>\n</li>\n\n";
    $next_id++;
}

sub print_atom_unread {
    my ($file, %args) = @_;
    my $path = '/feed/entry';
    my $xp = XML::XPath->new(filename => $file);
    foreach my $entry ($xp->find($path)->get_nodelist()) {
        my $title = $entry->findvalue('title');
	my $author = $entry->findvalue('author[1]/name');
	my $link = $entry->findvalue('link[1]/@href');
	$title = trim($title);
	$author =~ trim($author);
	$link =~ s/\s+//gs;
	print_li("<a href=\"" . quote($link) . "\">" . quote($args{'Prefix'}) . quote($title) . "</a>" . ($author ? (" <span class=\"author\">(" . quote($author) . ")</span>") : ""));
    }
}

sub print_atom_drafts {
    my ($file, $categories, %args) = @_;
    my $path;
    if ($categories eq "") {
        $path = "/feed/entry";
    } else {
	$path = join
	    (" | ", 
    	    map { "/feed/entry[category/\@term=\"$_\"]" } @$categories
	    );
    }
    my $doc = XML::XPath->new(filename => $file);
    my %data = ();
    foreach my $entry ($doc->find($path)->get_nodelist()) {
	my $doc = $entry->findvalue('title');
	$data{$doc} = $args{'OmitSummary'} ? "" : $entry->findvalue('summary');
    }
    print_start_ul("expands");
    foreach my $doc (sort keys %data) {
	print_doc($doc, $data{$doc}, $args{'Diff'} ? "diff" : "");
    }
    print_end_ul();
}

#---------------------------------------------------------------------------

my $file = "$newer/download_data.txt";
open(IN, $file) || die "$file: $!\n";
my $newer_t = int(<IN>);
close IN;

$file = "$newer/download_data_previous.txt";
open(IN, $file) || die "$file: $!\n";
my $older_t = int(<IN>);
close IN;

open(OUTPUT, ">:utf8", $output_left) || die "$output_left: $!\n";
select OUTPUT;

my $newer_t_str = strftime("%Y-%m-%d", gmtime($newer_t));

print "<!-- DAILY CONTENT BEGINS -->\n";
print "<!-- DATE=$newer_t_str $older_t $newer_t -->\n";
print "<!-- LAYOUT=V2 -->\n";

#---------------------------------------------------------------------------

if (-e "$older/1id-abstracts.txt") {
    read_id_abstracts("$older/1id-abstracts.txt");
}
read_id_abstracts("$newer/1id-abstracts.txt");

read_id_statuses();

#---------------------------------------------------------------------------

print "<h2>IETF-Announce List</h2>\n";
print_start_ul("links");
print_atom_unread("$newer/ietf_announce_nonrfc_unread.xml");
print_end_ul();

print '<div class="more"><a href="https://www.ietf.org/mail-archive/web/ietf-announce/">more messages &raquo;</a></div>', "\n\n";

print '<h2><a href="https://tools.ietf.org/html/new-rfcs.rss"><img src="feedicon16.png" style="float:right;" alt="[Feed]" /></a> New RFCs</h2>', "\n";
print_start_ul("links");
print_atom_unread("$newer/ietf_announce_rfc_unread.xml");
print_end_ul();

print '<div class="more"><a href="http://www.rfc-editor.org/new_rfcs.html">more recent RFCs &raquo;</a></div>', "\n\n";

#---------------------------------------------------------------------------

print "<h2>New and Revived Drafts</h2>\n";

print_atom_drafts("$newer/draft_updates_atom.xml", 
		  ["new", "revived"],
		  Diff => 1, OmitSummary => 1);

print "<h2>Updated Drafts</h2>\n";

print_atom_drafts("$newer/draft_updates_atom.xml",
		  ["updated"],
		  Diff => 1, OmitSummary => 1);

print "<h2>Expired Drafts</h2>\n";

print_atom_drafts("$newer/draft_updates_atom.xml",
		  ["expired"],
		  OmitSummary => 1);

#---------------------------------------------------------------------------

close OUTPUT;
open(OUTPUT, ">:utf8", $output_right) || die "$output_right: $!\n";
select OUTPUT;

#---------------------------------------------------------------------------

print "<h2>Drafts Sent to IESG</h2>\n\n";

print_atom_drafts("$newer/draft_updates_atom.xml",
		  ["to-iesg"]);

print "<h2>IESG Progress</h2>\n";

print_atom_drafts("$newer/draft_updates_atom.xml",
		  ["iesg-progress"]);

print "<h2>Drafts Sent to RFC Editor</h2>\n";

print_atom_drafts("$newer/draft_updates_atom.xml",
		  ["to-rfc-editor"]);

print "<h2>Other Status Changes</h2>\n";

print_atom_drafts("$newer/draft_updates_atom.xml",
		  ["other"]);

#---------------------------------------------------------------------------

print "<h2>RFC Editor Status Changes</h2>\n";

print_atom_drafts("$newer/rfcq_progress_atom.xml", "");

#---------------------------------------------------------------------------

print '<h2><a href="https://datatracker.ietf.org/feed/ipr/"><img src="feedicon16.png" align="right" alt="[Feed]" /></a> IPR Disclosures</h2>', "\n";

print_start_ul("links");
print_atom_unread("$newer/ipr_disclosures_unread.xml");
print_end_ul();

print '<div class="more"><a href="https://datatracker.ietf.org/ipr/">more IPR disclosures &raquo;</a></div>', "\n\n";

#---------------------------------------------------------------------------

print "<h2>IESG/IAB/IAOC/Trust Minutes</h2>\n";

print_start_ul("links");
print_atom_unread("$newer/iesg_minutes_unread.xml");
print_atom_unread("$newer/iesg_narrative_unread.xml");
print_atom_unread("$newer/iab_minutes_unread.xml");
print_atom_unread("$newer/iaoc_minutes_unread.xml");
print_atom_unread("$newer/trust_minutes_unread.xml");
print_end_ul();

print '<div class="more">more minutes: <a href="https://www.ietf.org/iesg/minutes.html">IESG &raquo;</a> &nbsp; <a href="https://www.iab.org/documents/minutes/">IAB &raquo;</a> &nbsp; <a href="https://iaoc.ietf.org/minutes.html">IAOC &raquo;</a> &nbsp; <a href="https://trustee.ietf.org/minutes.html">Trust &raquo;</a></div>', "\n\n";

#---------------------------------------------------------------------------

print "<h2>Liaison Statements</h2>\n";

print_start_ul("links");
print_atom_unread("$newer/liaisons_unread.xml");
print_end_ul();

print '<div class="more"><a href="https://datatracker.ietf.org/liaison/">more liaison statements &raquo;</a></div>', "\n";

#---------------------------------------------------------------------------

print "<!-- DAILY CONTENT ENDS -->\n";

close OUTPUT;
