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
# Simple module for writing Atom feeds. Supports only a limited 
# set of elements.
#
package MyAtomWriter;
use XML::Writer;
use strict;
use Time::Local;
use IO::String;
use POSIX qw(strftime);

my $DATE_FORMAT = "%Y-%m-%dT%H:%M:%SZ";

sub new {
    my $self = {};
    $self->{WRITER} = new XML::Writer(OUTPUT => IO::String->new);
    bless($self);
    return $self;
}

sub feed {
    my $self = shift;
    my %arg = @_;
    
    my $w = $self->{WRITER};
    $w->xmlDecl('UTF-8');
    $w->startTag('feed', 'xmlns' => 'http://www.w3.org/2005/Atom');
    $w->dataElement('title', $arg{'title'});
    $w->emptyTag('link', 'href' => $arg{'link'});
    if (exists $arg{'self'}) {
	$w->emptyTag('link', 'href' => $arg{'self'}, 'rel' => 'self');
    }
    $w->dataElement('id', $arg{'id'});
    $w->startTag('author');
    $w->dataElement('name', $arg{'author'});
    $w->endTag();
    $w->dataElement('updated', strftime($DATE_FORMAT, gmtime(time())));
}

sub entry {
    my $self = shift;
    my %arg = @_;

    my $w = $self->{WRITER};
    $w->startTag('entry');

    foreach my $tag ('title', 'summary', 'id') {
        if (exists $arg{$tag}) {
            $w->dataElement($tag, $arg{$tag});
        }
    }
    $w->emptyTag('link', 'href' => $arg{'link'});
    if (exists $arg{'author'}) {
	$w->startTag('author');
	$w->dataElement('name', $arg{'author'});
	$w->endTag();
    }
    if (exists $arg{'category'}) {
	$w->emptyTag('category', 'term' => $arg{'category'});
    }
    my $updated = undef;
    if (!exists $arg{'updated'}) {
    } elsif ($arg{'updated'} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/) {
        my $year = $1;
        my $month = $2;
        my $mday = $3;
        $year = 2000 if ($year == 0);
        $updated = strftime($DATE_FORMAT,
			    gmtime(timegm(0, 0, 0,
					  $mday, $month-1, $year-1900, 0,
					  0)));
    } elsif ($arg{'updated'} =~ /^\d+$/) {
        $updated = strftime($DATE_FORMAT, gmtime($arg{'updated'}));
    } elsif ($arg{'updated'} =~ /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d/) {
	$updated = $arg{'updated'};
    }
    if ($updated) {
        $w->dataElement('updated', $updated);
    }
    $w->endTag();
}

sub as_string {
    my $self = shift;
    my $w = $self->{WRITER};
    $w->endTag();
    $w->end();
    my $s = ${$w->getOutput()->string_ref()}; 
    $s =~ s/<entry>/\n\n<entry>/gi;
    return $s;
}

sub write_to_file {
    my $self = shift;
    my $filename = shift;
    open(OUTPUT, ">:utf8", $filename) || return 0;
    print OUTPUT $self->as_string();
    close OUTPUT;
    return 1;
}

1;
