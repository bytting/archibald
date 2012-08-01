#!/usr/bin/perl -w
#=======================================================================

use strict;
use warnings;
use IO::Handle;
use Arch_UI;

use strict 'subs';

open STDERR, ">stderr.log" or die $!;
STDERR->autoflush(1);

Arch_UI::run();

#=======================================================================