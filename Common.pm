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

our (%win,
     $g_keymap,
     $g_keymap_directory,
     $g_keymap_extension,
     $g_font,
     $g_font_directory,
     $g_font_extension,
     $g_fontmap,
     $g_fontmap_directory,
     $g_fontmap_extension,
     $g_bootloader,
     $g_wirelesstools,
     @g_partition_table,
     @g_available_partitions,
     $g_mirrorlist,
     @g_mirrors,
     $g_timezone_directory,
     $g_locale_gen,
     $g_rc_conf,
     $g_timezone,
     $g_use_localtime,
     @g_locales,
     $g_locale_lang,
     $g_locale_time,
     $g_hostname,
     $g_interface,
     $g_static_ip,
     $g_ip,
     $g_domain,
     $g_netmask,
     $g_gateway,
     $g_disk,
     %g_disks,
     @g_mountpoints,
     $g_install_script,
     $g_partitioning_scheme,
     $g_boot_disk);

# Default values
%win = ();
$g_keymap = 'us';
$g_keymap_directory = '/usr/share/kbd/keymaps/';
$g_keymap_extension = '.map.gz';
$g_font_directory = '/usr/share/kbd/consolefonts/';
$g_font_extension = '.gz';
$g_fontmap_directory = '/usr/share/kbd/consoletrans/';
$g_fontmap_extension = '.trans';
$g_mirrorlist = '/etc/pacman.d/mirrorlist';
$g_timezone_directory = '/usr/share/zoneinfo/';
$g_locale_gen = '/etc/locale.gen';
$g_rc_conf = '/etc/rc.conf';
$g_install_script = 'arch-install';

#=======================================================================
1;