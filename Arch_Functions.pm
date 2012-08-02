#!/usr/bin/perl
#=======================================================================

package Arch_Functions;

use strict;
use warnings;
use File::Find;

sub get_files_from {
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
1;