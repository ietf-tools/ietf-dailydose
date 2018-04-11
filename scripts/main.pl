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

my $BASE_URL = "https://tools.ietf.org/dailydose/";
my $DIR = "/www/tools.ietf.org/dailydose";
my $DATA = $DIR . "/data"; 
my $PERL = 'perl';

select STDERR; $|=1;
select STDOUT; $|=1;

my $hostname = `hostname`;
$hostname =~ s/\s+//gs;
my $PRIMARY = 0;
if ($hostname =~ /durif/) {
    $PRIMARY = 1;
} 
print "main: starting on $hostname (", ($PRIMARY ? "" : "not "), "primary)\n";
print "main: time is ", scalar(localtime), "\n\n";

if (!-d $DATA) {
    die "main: data directory not found\n";
}

# Determine old directory/date

my $file = "$DATA/previous.txt";
open(IN, $file) || die "$file: $!\n";
my $data_old_t = int(<IN>);
close IN;
my $data_old = "$DATA/$data_old_t";
print "\nmain: old data is $data_old\n";

# Download data to data/tmp directory and check it

system("rm -rf $DATA/tmp");
system("mkdir $DATA/tmp") && die "main: mkdir failed\n";

if ((system("$PERL download_data.pl $data_old $DATA/tmp") != 0) ||
    (system("$PERL check_data.pl $DATA/tmp") != 0)) {
    die "main: download/check failed\n";
} 
    
# Determine new directory/date

$file = "$DATA/tmp/download_data.txt";
open(IN, $file) || die "$file: $!\n";
my $data_new_t = int(<IN>);
close IN;
rename("$DATA/tmp", "$DATA/$data_new_t") || die "main.pl: $!\n";
my $data_new = "$DATA/$data_new_t";

$file = "$data_new/download_data_previous.txt";
open(OUTPUT, ">", $file) || die "$file: $!\n";
print OUTPUT $data_old_t, "\n";
close OUTPUT;

print "main: new data is $data_new\n";

# Run scripts

foreach my $script (
		    "draft_updates_atom.pl",
		    "ietf_announce_atom.pl",
		    "atom_unread.pl ietf_announce_nonrfc",
		    "atom_unread.pl ietf_announce_rfc",
		    "atom_unread.pl ipr_disclosures",
		    "liaisons_atom.pl",
		    "atom_unread.pl liaisons",
		    "iesg_minutes_atom.pl",
		    "atom_unread.pl iesg_minutes",
		    "atom_unread.pl iesg_narrative",
		    "iab_minutes_atom.pl",
		    "atom_unread.pl iab_minutes",
		    "iaoc_minutes_atom.pl",
		    "atom_unread.pl iaoc_minutes",
		    "trust_minutes_atom.pl",
		    "atom_unread.pl trust_minutes",
                    "rfcq_progress_atom.pl",
		    "make_daily_content.pl") {
    if (system("$PERL $script $data_old $data_new") != 0) {
	die "main: something failed in $script\n";
    }
}     

# Determine issue number

$file = "$DIR/latest_issue.txt";
open(IN, $file) || die "$file: $!\n";
my $issue = int(<IN>) + 1;
close IN;

# Build issue and update feeds

print "main: building issue $issue\n";
system("$PERL new_issue.pl $data_new $issue $DIR" . ($PRIMARY ? "" : " --not-primary")) 
    && die "main: new_issue failed\n";

print "main: committing state\n";

$file = "$DIR/latest_issue.html";
open(OUTPUT, ">", $file) || die "$file: $!\n";
print OUTPUT "<!--#set var=\"latest_issue\" value=\"$issue\" -->\n";
close OUTPUT;

$file = "$DIR/latest_issue.txt";
open(OUTPUT, ">", $file) || die "$file: $!\n";
print OUTPUT $issue, "\n";
close OUTPUT;

$file = "$DATA/previous.txt";
open(OUTPUT, ">", $file) || die "$file: $!\n";
print OUTPUT $data_new_t, "\n";
close OUTPUT;

print "main: committed\n\n";

system("$PERL update_feeds.pl $DIR $BASE_URL") && die "main: update_feeds failed\n";

system("$PERL remove_old_data.pl $DATA") && die "main: remove_old_data failed\n";

print "main: done\n";

exit 0;
