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
# Simple module for writing RSS feeds. Supports only a limited
# set of elements. 
#
# Known limitations:
# - Does not use XML::Writer, so sort of kludge.
# - Not UTF-8 compliant.
#
package MyRSSWriter;
use strict;
use Time::Local;
use POSIX qw(strftime);

my $DATE_FORMAT = "%a, %d %h %Y %H:%M:%S GMT";

sub quote {
    my ($s) = @_;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    return $s;
}

sub new {
    my $self = {};
    $self->{DATA} = "";
    bless($self);
    return $self;
}

sub channel {
    my $self = shift;
    my %arg = @_;
    $self->{DATA} .= 
	("<channel>\n" .
	 "<title>" . quote($arg{'title'}) . "</title>\n" .
	 "<link>". quote($arg{'link'}) . "</link>\n" .
	 "<description>" . quote($arg{'description'}) . "</description>\n" .
	 "<lastBuildDate>" . 
	 strftime($DATE_FORMAT, gmtime(time())) .
	 "</lastBuildDate>\n");
}

sub add_item {
    my $self = shift;
    my %arg = @_;
    $self->{DATA} .= "<item>\n";
    foreach my $tag ('title', 'link', 'description') {
	if (exists $arg{$tag}) {
	    $self->{DATA} .= ("  <$tag>" . quote($arg{$tag}) . "</$tag>\n");
	}
    } 
    if (exists $arg{'guid'}) {
	$self->{DATA} .= ("  <guid>" . quote($arg{'guid'}) . "</guid>\n");
    } 
    if ($arg{'pubDate'} =~ /^\d+$/) {
	$self->{DATA} .= ("  <pubDate>" .
			  strftime($DATE_FORMAT, gmtime($arg{'pubDate'})) .
			  "</pubDate>\n");
    }
    $self->{DATA} .= "</item>\n";
}  

sub as_string {
    my $self = shift;
    return ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" .
	    "<rss version=\"2.0\">\n" .
	    $self->{DATA} . 
	    "</channel>\n</rss>\n");
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


