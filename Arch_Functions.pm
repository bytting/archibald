#!/usr/bin/perl
#=======================================================================

package Arch_Functions;

use strict;
use warnings;
use File::Find;

sub get_files_from {
    my $dir = shift;
    my $ext = shift;
    
    my @files;
    my $map_finder = sub {
        return unless -f;
        return unless /$ext$/;
        push @files, $File::Find::name;        
    };
    find($map_finder, $dir);
    return sort @files;
}
1;