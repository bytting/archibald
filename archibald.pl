#!/usr/bin/perl -w
#=======================================================================

use strict;
use warnings;
#use File::Temp qw( :POSIX );
use Arch_UI;

#my $fh = tmpfile();
#open STDERR, ">&fh";
open STDERR, ">stderr" or die $!;

Arch_UI::run();
