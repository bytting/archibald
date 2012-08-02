#!/usr/bin/env perl
#=======================================================================
# Arch_Common.pm - Common variables for archibald.pl
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

package Arch_Common;

use strict;
use warnings;

our ($keymap_directory, $keymap_extension, $keymap_mask, @partition_table, $mirrorlist);

$keymap_directory = '/usr/share/kbd/keymaps/';
$keymap_extension = '.map.gz';
$keymap_mask = [[ '\.map.gz$', "Keymap files (*$keymap_extension)" ]];

$mirrorlist = '/etc/pacman.d/mirrorlist';

#=======================================================================
1;