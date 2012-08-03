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
1;