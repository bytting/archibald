#!/usr/bin/perl -w
#=======================================================================

use strict;
use warnings;
use strict 'subs';
use IO::Handle;
use Arch_UI;

open STDERR, ">stderr.log" or die $!;
STDERR->autoflush(1);

Arch_UI::run();

#=======================================================================