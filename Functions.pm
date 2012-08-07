#!/usr/bin/env perl
#=======================================================================
# Arch_Functions.pm - Helper functions for archibald.pl
# Copyright (C) 2012  Dag Robøle
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#=======================================================================

use strict;
use warnings;
use File::Find;

#=======================================================================
# find_files_deep: Get a list of files recursively
#=======================================================================

sub find_files_deep
{
    my $dir = shift;
    my $ext = shift;
    
    return (1, ()) unless -d $dir;
    
    my @files;
    my $map_finder = sub {
        return unless -f;
        return unless /$ext$/;
        push @files, $File::Find::name;        
    };
    find($map_finder, $dir);
    return (0, sort @files);
}

#=======================================================================
# find_zoneinfo: Get a list of available zones
#=======================================================================

sub find_zoneinfo
{
    my $dir = shift;    
    
    return (1, ()) unless -d $dir;
    
    my @entries;
    my $map_finder = sub {
        return unless /^[A-Z]/;
        push @entries, $File::Find::name;        
    };
    find($map_finder, $dir);
    return (0, sort @entries);
}

#=======================================================================
# emit: Emit text to a file handle
#=======================================================================

sub emit
{
    my ($handle, $cmd) = @_;
    print $handle "$cmd";
}

#=======================================================================
# emit: Emit bash to a file handle with newline
#=======================================================================

sub emit_bash
{
    my ($handle, $cmd) = @_;
    emit($handle, "$cmd\n");
}

#=======================================================================
# emit: Emit bash to a file handle including status messages
#=======================================================================

sub emit_bash_with_check
{
    my ($handle, $cmd, $msg_success, $msg_error) = @_;
    emit_bash($handle, "$cmd");
    print $handle "if [ \"\$?\" -ne \"0\" ]; then\n\techo \"$msg_error\\n\"\nelse\n\techo \"$msg_success\\n\"\nfi\n";
}

#=======================================================================
1;