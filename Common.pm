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

use strict;
use warnings;

our ($g_keymap,
     $g_keymap_directory,
     $g_keymap_extension,
     $g_bootloader,
     $g_wirelesstools,
     @g_partition_table,
     $g_mirrorlist,
     @g_mirrors,
     $g_timezone_directory,
     $g_locale_gen,
     $g_rc_conf,
     $g_timezone,
     @g_locales,
     $g_locale_lang,
     $g_hostname,
     $g_interface,
     $g_static_ip,
     $g_ip,
     $g_domain,
     $g_disk);

# Default values
$g_keymap = 'us';
$g_keymap_directory = '/usr/share/kbd/keymaps/';
$g_keymap_extension = '.map.gz';
$g_mirrorlist = '/etc/pacman.d/mirrorlist';
$g_timezone_directory = '/usr/share/zoneinfo/';
$g_locale_gen = '/etc/locale.gen';
$g_rc_conf = '/etc/rc.conf';

#=======================================================================
1;