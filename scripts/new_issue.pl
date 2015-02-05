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

sub cp_filter_ssi {
    my ($file1, $file2) = @_;
    open(IN, "<:utf8", $file1) || die "$file1: $!\n";
    open(OUT, ">:utf8", $file2) || die "$file2: $!\n";
    while ($_ = <IN>) {
	if (/<!--#/) {
	    print STDERR "new_issue: SSI found in $file1\n";
            s/<!--#/<!--hash/g;
	}    
        print OUT $_;
    } 
    close IN;
    close OUT;
}

sub read_schedule {
    my ($file) = @_;
    open(IN, "<:utf8", $file) || die "$file: $!\n";
    my $terminator = $/;
    undef $/;
    my $s = <IN>;
    close IN;
    $/ = $terminator;
    
    $s =~ s/\s+/ /gs;
    if ($s =~ /^\s*\[(.*)\]\s*$/) {
	$s = $1;
    } else {
	return undef;
    }
    my @a = ();
    while ($s =~ m/\s*{([^}]*)}\s*,?/g) {
	my $t = $1;
	my $o = {};
	while ($t =~ m/\s*["']([-\w]+)["']\s*:\s*["']([-\w]*)["']\s*,?/g) {
	    $$o{$1} = $2;
	}
	push @a, $o;
    }
    return @a;
}

sub select_schedule_entry {
    my ($today, @schedule) = @_;
    my @sorted_schedule = sort { $$a{'date'} cmp $$b{'date'} } @schedule;
    my $prev_entry;
    foreach my $entry (@sorted_schedule) {
	if ($$entry{'date'} eq $today) {
	    return $entry;
	} elsif ($$entry{'date'} gt $today) {
	    return $prev_entry;
	}
	$prev_entry = $entry;
    }
    return undef;
}

my $PRIMARY = 1;
if ((@ARGV == 4) && ($ARGV[3] eq "--not-primary")) {
    $PRIMARY = 0;
    pop @ARGV;
}

die "usage: new_issue data-dir issue-number output-dir\n" unless (@ARGV == 3);
my $newer = $ARGV[0];
my $issue = $ARGV[1];
my $dir = $ARGV[2];
my $output = "$dir/$issue.html";
my $schedule_file = "$dir/articles/schedule";

my $prev_issue = $issue-1;
my $next_issue = $issue+1;
my $last_updated_t = time();
my $last_updated = strftime("%Y-%m-%d %H:%M:%S GMT", gmtime($last_updated_t));
my $issue_date = "";

my $file = "$newer/content_left.txt";
open(INPUT, "<:utf8", $file) || die "$file: $!\n";
while ($_ = <INPUT>) {
    if (/<!-- DATE=(\S+)/) {
	$issue_date = $1;
	last;
    }
}
close INPUT;
die "new_issue: date not found" unless ($issue_date);

cp_filter_ssi("$newer/content_left.txt", "$dir/${issue}_left.html");
cp_filter_ssi("$newer/content_right.txt", "$dir/${issue}_right.html");

my @schedule = read_schedule($schedule_file);
my $schedule_entry = select_schedule_entry($issue_date, @schedule);

open(OUTPUT, ">:utf8", $output) || die "$output: $!\n";
select OUTPUT;
print <<"END";
<!--#set var="issue" value="$issue" -->
<!--#set var="prev_issue" value="$prev_issue" -->
<!--#set var="next_issue" value="$next_issue" -->
<!--#set var="issue_date" value="$issue_date" -->
<!--#set var="last_updated" value="$last_updated" -->
END
if (!$PRIMARY) {
    print "<!--#set var=\"not_primary_server\" value=\"1\" -->\n";
}

foreach my $key ('lead','second','ad1','ad2','ad3') {
    if ($$schedule_entry{$key}) {
	print "<!--#set var=\"$key\" value=\"", $$schedule_entry{$key}, "\" -->\n";
    }
}

print <<"END";

<!--#include virtual="layout_v2.html" -->
<!-- DATE=$issue_date $last_updated_t -->
END

close OUTPUT;

