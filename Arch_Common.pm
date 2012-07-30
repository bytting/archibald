#!/usr/bin/perl -w
#=======================================================================

package Arch_Common;

use strict;
use warnings;

our ($keymap_directory, $keymap_extension, $keymap_mask);

$keymap_directory = '/usr/share/kbd/keymaps';
$keymap_extension = '.map.gz';
$keymap_mask = [[ '\.map.gz$', "Keymap files (*$keymap_extension)" ]];

#=======================================================================
1;