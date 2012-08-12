#!/usr/bin/env perl
#=======================================================================
# Arch_Callbacks.pm - Callbacks for archibald.pl
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

#package Arch_Callbacks;

use strict;
use warnings;
use File::Basename;
use feature qw(switch);
require Common;
require Functions;

use vars qw(%win);

#=======================================================================
# Callbacks - Main menu
#=======================================================================
    
sub MM_focus {
    my $win = shift;
    my $viewer = $win->getobj('viewer');
    my $nav = $win->getobj('nav');
    
    $viewer->text("Welcome to Archibald...\nYou can press CTRL+q to quit without saving at any time.\nFields marked with an asterisk is required for a minimal configuration.\nPress continue to start");
    
    $nav->focus;
}

#=======================================================================
# Callbacks - Configure keymap
#=======================================================================

sub CK_focus
{
    use vars qw($g_keymap_directory $g_keymap_extension $g_font_directory $g_font_extension $g_fontmap_directory $g_fontmap_extension);
    
    my $win = shift;
    my $info = $win->getobj('info');
    my $keymaplist = $win->getobj('keymaplist');
    my $fontlist = $win->getobj('fontlist');
    my $fontmaplist = $win->getobj('fontmaplist');    
    
    # setup keymaps    
    my ($err, @keymaps, @fonts, @fontmaps);
    ($err, @keymaps) = find_files_deep($g_keymap_directory, $g_keymap_extension);
    if($err) {
        $info->text('No keymaps found');
        return;
    }
    
    foreach (@keymaps) {
        s/^$g_keymap_directory//;
        s/$g_keymap_extension$//;
    }
    
    $keymaplist->values(\@keymaps);
    
    # setup fonts
    ($err, @fonts) = find_files_deep($g_font_directory, $g_font_extension);
    if($err) {
        $info->text('No fonts found');
        return;
    }
    
    foreach (@fonts) {
        s/^$g_font_directory//;
        s/$g_font_extension$//;
        s/\.psf[u]*$//;
        s/\.fnt$//;
    }
    
    $fontlist->values(\@fonts);
    
    # setup fontmaps
    ($err, @fontmaps) = find_files_deep($g_fontmap_directory, $g_fontmap_extension);
    if($err) {
        $info->text('No fontmaps found');
        return;
    }
    
    foreach (@fontmaps) {
        s/^$g_fontmap_directory//;
        s/$g_fontmap_extension$//;
        s/_to_.*$//;
    }
    
    $fontmaplist->values(\@fontmaps);    
}

sub CK_nav_continue
{
    use vars qw($g_keymap $g_font $g_fontmap);
    
    my $bbox = shift;
    my $win = $bbox->parent;    
    my $info = $win->getobj('info');
    my $keymaplist = $win->getobj('keymaplist');
    my $fontlist = $win->getobj('fontlist');
    my $fontmaplist = $win->getobj('fontmaplist');
    
    my $keymap = $keymaplist->get();    
    
    unless(defined $keymap) {
        $info->text("You must select a keymap");
        return;
    }
    
    $g_keymap = (split(/\//, $keymap))[-1];    
    `loadkeys $g_keymap`;
    
    $g_font = $fontlist->get();
    $g_fontmap = $fontmaplist->get();
    
    $win{'SPS'}->focus;
}

#=======================================================================
# Callbacks - Select partitioning scheme
#=======================================================================

sub SPS_focus
{    
    my $win = shift;
    my $info = $win->getobj('info');    
            
    $info->text('Select a partitioning scheme');
}

sub SPS_nav_continue
{
    use vars qw($g_partitioning_scheme);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $schemelist = $win->getobj('schemelist');    
            
    $g_partitioning_scheme = $schemelist->get();        
    unless(defined $g_partitioning_scheme) {
        $info->text('You must select a partitioning scheme');
        return;
    }    
    
    given($g_partitioning_scheme) {
        when('guided') {
            $win{'GP'}->focus;
        }
        when('gdisk') {
            $win{'SD'}->focus;
        }
        when('fdisk') {
            $win{'SD'}->focus;
        }
    }    
}

#=======================================================================
# Callbacks - Guided partitioning
#=======================================================================

sub GP_focus
{
    use vars qw(%g_disks);
    
    my $win = shift;    
    my $info = $win->getobj('info');    
    my $devicelist = $win->getobj('devicelist');
    my $parttable = $win->getobj('parttable');      
    
    my (@sd_disks, @hd_disks);
    @sd_disks = glob("/sys/block/sd*");
    @hd_disks = glob("/sys/block/hd*");
    foreach (@sd_disks, @hd_disks) {
        open FILE, "<$_/size";
        my $contents = do { local $/; <FILE> };
        if($contents > 0) {
            s/^\/sys\/block\///;
            $g_disks{$_} = $contents * 512 / 1000 / 1000 - 1;
        }
    }    
        
    $devicelist->values(sort keys %g_disks);
    $parttable->values([]);
    $devicelist->focus;
    $info->text('Select a disk');    
}

sub GP_devicelist_change
{
    use vars qw(%g_disks @g_partition_table $g_disk);
    
    my $bbox = shift;
    my $win = $bbox->parent;    
    my $info = $win->getobj('info');
    my $nav = $win->getobj('nav');
    my $parttable = $win->getobj('parttable');
    my $devicelist = $win->getobj('devicelist');    
    my $device = $devicelist->get();    
    
    $g_disk = "/dev/$device";
    my $size = $g_disks{$device};
    if($size < 7250) {
        $info->text('Disk is too small for guided partitioning');
        return;
    }
        
    my $rest = int($g_disks{$device} - 2 - 200 - 2048);
    my $partnr = 1;
    my $bios = "$g_disk" . $partnr++ . ":bios:bios:2";
    my $boot = "$g_disk" . $partnr++ . ":boot:ext2:200";    
    my $swap = "$g_disk" . $partnr++ . ":swap:swap:2048";
    my $root = "$g_disk" . $partnr++ . ":root:ext4:$rest";
    
    @g_partition_table = ($bios, $boot, $swap, $root);
    
    $parttable->values(\@g_partition_table);
    $parttable->draw(0);
    $nav->focus;
}

#=======================================================================
# Callbacks - Select disk
#=======================================================================

sub SD_focus
{
    use vars qw(%g_disks);
    
    my $win = shift;    
    my $info = $win->getobj('info');
    my $devicelist = $win->getobj('devicelist');        

    my (@sd_disks, @hd_disks);
    @sd_disks = glob("/sys/block/sd*");
    @hd_disks = glob("/sys/block/hd*");
    foreach (@sd_disks, @hd_disks) {
        open FILE, "<$_/size";
        my $contents = do { local $/; <FILE> };
        if($contents > 0) {
            s/^\/sys\/block\///;
            $g_disks{$_} = $contents * 512 / 1000 / 1000 - 1;
        }
    }    
        
    $devicelist->values(sort keys %g_disks);    
    $devicelist->focus;
    $info->text('Select a disk...');
}

sub SD_devicelist_change
{
    use vars qw($g_disk);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $devicelist = $win->getobj('devicelist');
    my $viewer = $win->getobj('viewer');    
    
    my $dev = $devicelist->get();
    $g_disk = "/dev/$dev";
        
    my $out = `parted $g_disk print`;    
    $viewer->text($out);
}

#=======================================================================
# Callbacks - Manual partitioning
#=======================================================================

sub MP_focus
{
    use vars qw($g_disk @g_mountpoints @g_available_partitions @g_partition_table $g_partitioning_scheme);
    
    my $win = shift;
    my $cui = $win->parent;
    my $info = $win->getobj('info');
    my $partlist = $win->getobj('partlist');
    my $mountlist = $win->getobj('mountlist');
    my $fslist = $win->getobj('fslist');        
    
    @g_available_partitions = ();
    @g_partition_table = ();
    
    $cui->leave_curses();
    system("clear && $g_partitioning_scheme $g_disk");
    $cui->reset_curses();
    
    $mountlist->clear_selection();
    $fslist->clear_selection();
    
    my @pi;
    my @p = `parted $g_disk print`;
    foreach(@p) {
        if(/^\s\d\s/) {
            s/^\s*//;
           @pi = split(/\s+/, $_);
           push @g_available_partitions, "$g_disk$pi[0]";
        }
    }
    
    @g_mountpoints = ('bios', 'boot', 'swap', 'root', 'home', 'usr', 'var', 'dev', 'sys');    
    
    $partlist->values(\@g_available_partitions);
    $mountlist->values(\@g_mountpoints);
    $fslist->values('ext2', 'ext3', 'ext4');
    
    $info->text('Select a mountpoint...');
}

sub MP_mountlist_change
{
    my $mountlist = shift;
    my $win = $mountlist->parent;    
    my $fslist = $win->getobj('fslist');
    
    my $mountpoint = $mountlist->get();
    unless(defined $mountpoint) { return }
    
    given($mountpoint) {
        when('bios') {
            $fslist->values('bios');
            $fslist->set_selection(0);
        }
        when('swap') {
            $fslist->values('swap');
            $fslist->set_selection(0);
        }
        default {
            $fslist->values('ext2', 'ext3', 'ext4');
        }
    }
    
    $fslist->focus;    
}

sub MP_mountlist_focus
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    $info->text('Select a mount point...');
}

sub MP_fslist_change
{    
    #my $bbox = shift;
    #my $win = $bbox->parent;                
}

sub MP_fslist_focus
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    $info->text('Select a file system type...');
}
 
sub MP_nav_focus
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    $info->text('');
}
 
sub MP_nav_add
{
    use vars qw(@g_partition_table @g_mountpoints);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $remsize = $win->getobj('remsize');    
    my ($partlist, $mountlist, $fslist, $partsize, $parttable) = (
        $win->getobj('partlist'), $win->getobj('mountlist'), $win->getobj('fslist'), $win->getobj('partsize'), $win->getobj('parttable')
    );                
    
    my $dev = $partlist->get();    
    my $entry = $dev . ':' . $mountlist->get() . ':' . $fslist->get();
    
    push @g_partition_table, $entry;
            
    @g_available_partitions = grep { $_ ne $dev } @g_available_partitions;
    $partlist->values(\@g_available_partitions);
    
    my $item = $mountlist->get();
    @g_mountpoints = grep { $_ ne $item } @g_mountpoints;
    $mountlist->values(\@g_mountpoints);
    
    $parttable->values(\@g_partition_table);
    
    $fslist->clear_selection();
    
    $parttable->draw(0);     
    $partlist->focus;
    
    $info->text('Entry added...');
}

sub MP_nav_clear
{
    use vars qw(@g_partition_table @g_available_partitions);
    
    my $bbox = shift;
    my $win = $bbox->parent;    
    my ($partlist, $mountlist, $fslist) = ($win->getobj('partlist'), $win->getobj('mountlist'), $win->getobj('fslist'));
    my $parttable = $win->getobj('parttable');
           
    @g_available_partitions = ();
    my @pi;
    my @p = `parted $g_disk print`;
    foreach(@p) {
        if(/^\s\d\s/) {
            s/^\s*//;
           @pi = split(/\s+/, $_);
           push @g_available_partitions, "$g_disk$pi[0]";
        }
    }
    
    $partlist->values(\@g_available_partitions);
    
    $mountlist->clear_selection();
    @g_mountpoints = ('bios', 'boot', 'swap', 'root', 'home', 'usr', 'var', 'dev', 'sys');
    $mountlist->values(\@g_mountpoints);
    $fslist->clear_selection();    
    @g_partition_table = ();    
    $parttable->values(\@g_partition_table);
    $parttable->draw(0);    
    $partlist->focus;
}

sub MP_nav_continue
{
    use vars qw(@g_partition_table $g_partitioning_scheme);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    if($g_partitioning_scheme eq 'gdisk') {
        my $bios_partitions = grep { $_ =~ /.+:bios:.+/ } @g_partition_table;
        if($bios_partitions < 1) {
            $info->text('You must configure a bios partition when creating a gpt disk');
            return;
        }
    }
    
    my $root_partitions = grep { $_ =~ /.+:root:.+/ } @g_partition_table;
        if($root_partitions < 1) {
            $info->text('You must select a root partition');
            return;
        }
    
    $win{'SM'}->focus;                      
}

#=======================================================================
# Callbacks - Select mirror
#=======================================================================

sub SM_focus
{
    use vars qw($g_mirrorlist);
    
    my $win = shift;
    my ($info, $mirrorlist) = ($win->getobj('info'), $win->getobj('mirrorlist'));    
    my ($prev, $url);
    
    unless(-e $g_mirrorlist) {
        $info->text("The file $g_mirrorlist was not found");
        return;
    }
    
    open FILE, $g_mirrorlist;
    my @content = <FILE>;
    close FILE;
    my %mirrors;
    foreach (@content) {
        if(/^\s*#*\s*Server\s*=\s*(.*)/) {
            $url = $1;
            $prev =~ s/^[\s#]*//;
            $mirrors{$url} = $prev;
        }
        $prev = $_;
    }
    
    $mirrorlist->values(map { "$mirrors{$_} - $_" } keys %mirrors);    
}

sub SM_nav_continue
{
    use vars qw($g_mirrorlist @g_mirrors);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my ($info, $mirrorlist) = ($win->getobj('info'), $win->getobj('mirrorlist'));            
    @g_mirrors = $mirrorlist->get();
    
    if(!@g_mirrors) {
        $info->text('You must select at least one mirror');
        return;
    }    
    
    $win{'SP'}->focus;
}

#=======================================================================
# Callbacks - Select packages
#=======================================================================

sub SP_focus
{       
    my $win = shift;
    my $info = $win->getobj('info');
    my $bootloaderlist = $win->getobj('bootloaderlist');
    my $devicelist = $win->getobj('devicelist');        

    my (@sd_disks, @hd_disks, @disks);
    @sd_disks = glob("/sys/block/sd*");
    @hd_disks = glob("/sys/block/hd*");
    foreach (@sd_disks, @hd_disks) {        
        s/^\/sys\/block\//\/dev\//;
        push @disks, $_;
    }    
        
    $devicelist->values(sort @disks);    
    $bootloaderlist->values(['grub']);
}

sub SP_nav_continue
{
    use vars qw($g_bootloader $g_boot_disk $g_wirelesstools);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $bootloaderlist = $win->getobj('bootloaderlist');
    my $devicelist = $win->getobj('devicelist');        
    my $wirelesstoolscb = $win->getobj('wirelesstoolscb');
    
    $g_bootloader = $bootloaderlist->get();
    $g_boot_disk = $devicelist->get();
    $g_wirelesstools = $wirelesstoolscb->get();    
    
    if(defined $g_bootloader) {
        unless(defined $g_boot_disk) {
            $info->text("You must select a boot device for $g_bootloader");
            return;
        }
    }    
    
    $win{'CS'}->focus;
}

#=======================================================================
# Callbacks - Configure system
#=======================================================================

sub CS_focus
{
    use vars qw($g_timezone_directory $g_locale_gen);
    
    my $win = shift;
    my $info = $win->getobj('info');
    my $timezonelist = $win->getobj('timezonelist');
    my $localelist = $win->getobj('localelist');
    my $localelist_lang = $win->getobj('localelist_lang');
    my $localelist_time = $win->getobj('localelist_time');
    
    # populate timezones    
    my ($err, @timezones) = find_zoneinfo($g_timezone_directory);
    if($err) {
        $info->text('No timezones found');
        return;
    }
    
    foreach (@timezones) {
        s/^$g_timezone_directory//;        
    }
    
    $timezonelist->values(\@timezones);
    
    # populate locale.gen        
    unless(-e $g_locale_gen) {
        $info->text("The file $g_locale_gen was not found");
        return;
    }
    
    open FILE, $g_locale_gen;
    my @content = <FILE>;
    close FILE;
    my @locales;
    foreach (@content) {
        if(/^#*[a-z]{2,3}_/) {
            s/^#*//;
            push @locales, $_;
        }        
    }
    
    $localelist->values(\@locales);
    $localelist_lang->values(\@locales);
    $localelist_time->values(\@locales);    
}

sub CS_nav_continue
{
    use vars qw($g_timezone @g_locales $g_locale_lang $g_locale_time $g_use_localetime);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $cui = $win->parent;
    my $info = $win->getobj('info');    
    my $timezonelist = $win->getobj('timezonelist');
    my $localelist = $win->getobj('localelist');
    my $localelist_lang = $win->getobj('localelist_lang');
    my $localelist_time = $win->getobj('localelist_time');
    my $localetimecb = $win->getobj('localetimecb');    
        
    $g_timezone = $timezonelist->get();
    unless(defined $g_timezone) {
        $info->text('You must select a timezone');
        return;
    }
    
    @g_locales = $localelist->get();
    if(!@g_locales) {
        $info->text('You must select at least one locale');
        return;
    }
    
    $g_locale_lang = $localelist_lang->get();
    unless(defined $g_locale_lang) {
        $info->text('You must select a language');
        return;
    }    
    $g_locale_lang =~ s/\s+.*//;
    chomp($g_locale_lang);
    
    $g_locale_time = $localelist_time->get();
    if(defined $g_locale_time) {
        $g_locale_time =~ s/\s+.*//;
        chomp($g_locale_time);
    }
    
    $g_use_localetime = $localetimecb->get();    
    
    $win{'CNET'}->focus;
}

#=======================================================================
# Callbacks - Configure networking
#=======================================================================

sub CNET_focus
{
    my $win = shift;
    my $info = $win->getobj('info');            
    my $iflist = $win->getobj('interfacelist');
    
    my @values;    
    my @ipc = `ip addr`;    
    
    for (@ipc) {
        if ( /^\d+:\s*(\w+).*state\s(\w+)/ ) {        
            my ($if, $state) = ($1, $2);
            if($if eq 'lo') {
                next;
            }
            push @values, "$if ($state)";            
        }
    }
        
    $iflist->values(\@values);            
}

sub CNET_interfacelist_changed
{
    my $interfacelist = shift;
    my $win = $interfacelist->parent;
    my $info = $win->getobj('info');
    my $staticipcb = $win->getobj('staticipcb');
    my $hostnameentry = $win->getobj('hostnameentry');
    my $ipentry = $win->getobj('ipentry');
    my $domainentry = $win->getobj('domainentry');
    
    my $item = $interfacelist->get();
    if($item) {
        $hostnameentry->title('Hostname *');
    }
    else {
        $hostnameentry->title('Hostname');
    }
}

sub CNET_staticip_changed
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $interfacelist = $win->getobj('interfacelist');
    my $hostnameentry = $win->getobj('hostnameentry');
    my $ipentry = $win->getobj('ipentry');
    my $domainentry = $win->getobj('domainentry');    
    
    my $items = $interfacelist->get();
    
    my $state = $bbox->get();
    if($state) {
        $interfacelist->title('Available network interfaces *');
        $hostnameentry->title('Hostname *');
        $ipentry->title('IP Address *');
        $domainentry->title('Domain *');
    }
    else {
        $interfacelist->title('Available network interfaces');
        if($items) {
            $hostnameentry->title('Hostname *');
        }
        else {
            $hostnameentry->title('Hostname');
        }        
        $ipentry->title('IP Address');
        $domainentry->title('Domain');
    }
}

sub CNET_nav_continue
{
    use vars qw($g_hostname $g_interface $g_static_ip $g_ip $g_domain);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $interfacelist = $win->getobj('interfacelist');
    my $hostnameentry = $win->getobj('hostnameentry');
    my $staticipcb = $win->getobj('staticipcb');        
    my $ipentry = $win->getobj('ipentry');
    my $domainentry = $win->getobj('domainentry');    
        
    $g_interface = $interfacelist->get();
    if(defined($g_interface))
    {
        $g_interface =~ s/\s+.*$//;
        
        $g_hostname = trim($hostnameentry->get());
        unless (length $g_hostname)
        {
            $info->text("You must choose a hostname for interface $g_interface");
            return;
        }        
        
        $g_static_ip = $staticipcb->get();
        if($g_static_ip)
        {
            $g_ip = trim($ipentry->get());
            unless(length $g_ip)
            {
                $info->text("You must choose a IP address for static interface $g_interface");
                return;
            }
            
            $g_domain = trim($domainentry->get());
            unless(length $g_domain)
            {
                $info->text("You must choose a domain for static interface $g_interface");
                return;
            }            
        }
    }            
    
    $win{'IS'}->focus;    
}

#=======================================================================
# Callbacks - Install
#=======================================================================

sub IS_focus
{
    my $win = shift;    
    my $opt = $win->getobj('opt');
        
    $opt->focus;
}

sub IS_nav_make_install
{
    use vars qw($g_keymap $g_font $g_fontmap $g_bootloader $g_wirelesstools @g_partition_table @g_mirrors
    $g_timezone $g_use_localetime @g_locales $g_locale_lang $g_hostname $g_interface $g_static_ip $g_ip
    $g_domain $g_disk $g_rc_conf $g_locale_lang $g_locale_time $g_install_script $g_partitioning_scheme);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $viewer = $win->getobj('viewer');

    # make sure all required variables are set
    
    unless(defined $g_disk) {
        $viewer->text('Disk undefined');
        return;
    }    
    
    # create and generate the installer script
        
    open my $inst, ">$g_install_script";    
    emit_line($inst, "#!/bin/bash");
    emit_line($inst, "set -e");    
    emit_line($inst, "if [[ \$1 != \"--configure\" ]]; then # This part runs before chroot");
    
    if($g_partitioning_scheme eq 'guided') {    
        emit_line($inst, "parted -s $g_disk mktable gpt");
        
        my $last_mountpoint;    
        foreach(@g_partition_table) {
            my ($partition, $mountpoint, $filesystem, $size) = split /:/;
            if(defined($last_mountpoint)) {
                emit_line($inst, "$mountpoint=\$((\$$last_mountpoint + $size))");
                emit_line($inst, "parted $g_disk unit MiB mkpart primary \$$last_mountpoint \$$mountpoint");
            }
            else {
                emit_line($inst, "$mountpoint=\$((1 + $size))");
                emit_line($inst, "parted $g_disk unit MiB mkpart primary 1 \$$mountpoint");
            }        
            $last_mountpoint = $mountpoint;
        }
    }
    
    emit($inst, "\n");
        
    my $separate_boot_partition = grep { $_ =~ /.+:boot:.+/ } @g_partition_table;    
        
    foreach(@g_partition_table) {
        my ($partition, $mountpoint, $filesystem, $size) = split /:/;
        given($filesystem) {
            when('ext2') {
                emit_line($inst, "mkfs.ext2 $partition");
            }
            when('ext3') {
                emit_line($inst, "mkfs.ext3 $partition");
            }
            when('ext4') {
                emit_line($inst, "mkfs.ext4 $partition");
            }
            when('swap') {
                emit_line($inst, "mkswap $partition");
                emit_line($inst, "swapon $partition");
            }
        }
        
        if($mountpoint eq 'root') {
            if(!$separate_boot_partition) {
                $partition =~ /.+(\d)$/;
                emit_line($inst, "parted $g_disk set $1 boot on");
            }
            emit_line($inst, "mount $partition /mnt");
        }        
    }
    
    emit($inst, "\n");    
        
    foreach(@g_partition_table) {
        my ($partition, $mountpoint, $filesystem, $size) = split /:/;
        $partition =~ /.+(\d)$/;
        my $partition_number = $1;
        given($mountpoint) {
            when('bios') {                
                emit_line($inst, "parted $g_disk set $partition_number bios_grub on");                                            
            }
            when('boot') {
                emit_line($inst, "parted $g_disk set $partition_number boot on");
                emit_line($inst, "mkdir /mnt/boot");
                emit_line($inst, "mount $partition /mnt/boot");
            }
            when('home') {
                emit_line($inst, "mkdir /mnt/home");
                emit_line($inst, "mount $partition /mnt/home");
            }
            when('usr') {
                emit_line($inst, "mkdir /mnt/usr");
                emit_line($inst, "mount $partition /mnt/usr");
            }
            when('var') {
                emit_line($inst, "mkdir /mnt/var");
                emit_line($inst, "mount $partition /mnt/var");
            }
            when('dev') {
                emit_line($inst, "mkdir /mnt/dev");
                emit_line($inst, "mount $partition /mnt/dev");
            }
            when('sys') {
                emit_line($inst, "mkdir /mnt/sys");
                emit_line($inst, "mount $partition /mnt/sys");
            }
        }        
    }
    
    emit($inst, "\n");    
    
    emit_line($inst, "pacstrap /mnt base base-devel");
    
    if($g_wirelesstools) {
        emit_line($inst, "pacstrap /mnt wireless_tools netcfg wpa_supplicant wpa_actiond");
    }
    
    if(defined $g_bootloader)
    {
        given($g_bootloader) {
            when('grub') {
                emit_line($inst, "pacstrap /mnt grub-bios");
            }
            when('syslinux') {
                emit_line($inst, "pacstrap /mnt syslinux");
            }
        }
    }
    
    emit($inst, "\n");
    
    emit_line($inst, "genfstab -p /mnt >> /mnt/etc/fstab");
    
    emit($inst, "\n");
    
    emit_line($inst, "mkdir -p /mnt/etc/archiso/");
    emit_line($inst, "cp /etc/archiso/functions /mnt/etc/archiso/functions");
    
    emit_line($inst, "cp $g_install_script /mnt/$g_install_script");
    emit_line($inst, "arch-chroot /mnt /$g_install_script --configure");
    
    emit($inst, "\n");
    
    # unmount
    
    foreach(@g_partition_table) {
        my ($dsk, $mount, $fs, $size) = split /:/;
        given($mount) {            
            when('boot') {                
                emit_line($inst, "umount /mnt/boot");
            }            
            when('home') {
                emit_line($inst, "umount /mnt/home");            
            }
            when('usr') {
                emit_line($inst, "umount /mnt/usr");                            
            }
            when('var') {
                emit_line($inst, "umount /mnt/var");                            
            }
            when('dev') {
                emit_line($inst, "umount /mnt/dev");                                            
            }
            when('sys') {
                emit_line($inst, "umount /mnt/sys");                            
            }
        }        
    }
    
    emit_line($inst, "umount /mnt");    
    
    emit_line($inst, "echo \"Installation was a success\"");
    
    emit_line($inst, "\n\nelse # This part runs in chroot\n\n");    
    
    # setup vconsole.conf
    
    emit_line($inst, "echo \"KEYMAP=$g_keymap\" > /etc/vconsole.conf");
    emit_line($inst, "echo \"FONT=$g_font\" >> /etc/vconsole.conf");
    emit_line($inst, "echo \"FONT_MAP=$g_fontmap\" >> /etc/vconsole.conf");
    
    emit($inst, "\n");        
    
    #setup mirrorlist
    
    if(@g_mirrors) {
        open (my $in, "<", $g_mirrorlist);
        open (my $out, ">", "./mirrorlist");    
    
        my $found;
        while(my $line = <$in>) {        
            if ($line =~ /^\s*$/) {
                print $out $line;
                next;
            }
            $found = 0;
            foreach(@g_mirrors) {
                $_ = (split(/\s/, $_))[-1];        
                if(index($line, $_) != -1) {
                    $found = 1;
                    $line =~ s/^[#\s]+//;                
                    print $out $line;
                    last;
                }
            }
            
            if(!$found) {
                if($line !~ /^#/) { print $out '#' . $line; }
                else { print $out $line; }
            }        
        }
        
        close $in;
        close $out;
                
        open MIRRORFILE, './mirrorlist';
        emit_line($inst, "cat > $g_mirrorlist << 'EOF'");
        while(<MIRRORFILE>) {            
            emit($inst, $_);
        }
        close MIRRORFILE;
        emit_line($inst, "EOF");
        unlink('./mirrorlist');
    }
    
    my ($in, $out);
    
    # setup locale
    
    open ($in, "<", $g_locale_gen);
    open ($out, ">", './locale.gen');    
    
    my $found;
    while(my $line = <$in>) {
        $found = 0;
        if ($line =~ /^#*[a-z]{2,3}_/) {            
            foreach(@g_locales) {                
                if(index($line, $_) != -1 or index($line, $g_locale_lang) != -1) {
                    $found = 1;
                    $line =~ s/^[#\s]+//;                
                    print $out $line;
                    last;
                }
            }            
        }        
        
        if(!$found) {
            if($line !~ /^#/) { print $out "#$line"; }
            else { print $out $line; }
        }        
    }
    
    close $in;
    close $out;
    
    emit($inst, "\n");
    
    open LOCFILE, './locale.gen';
    emit_line($inst, "cat > $g_locale_gen << 'EOF'");
    while(<LOCFILE>) {
        emit($inst, $_);
    }
    close LOCFILE;
    emit_line($inst, 'EOF');            
    unlink('./locale.gen');
    
    emit_line($inst, "locale-gen");
    
    emit($inst, "\n");
            
    emit_line($inst, "echo \"LANG=$g_locale_lang\" > /etc/locale.conf");
    emit_line($inst, "echo \"LC_TIME=$g_locale_time\" >> /etc/locale.conf");
    emit_line($inst, "echo \"LC_MESSAGES=C\" >> /etc/locale.conf");
        
    emit_line($inst, "ln -s /usr/share/zoneinfo/$g_timezone /etc/localtime");
    
    # setup hostname/hosts
    
    if(defined($g_hostname)) {
        emit_line($inst, "echo \"$g_hostname\" > /etc/hostname");
        
        emit_line($inst, "echo \"127.0.0.1    localhost.localdomain   localhost   $g_hostname\" > /etc/hosts");
        emit_line($inst, "echo \"::1          localhost.localdomain   localhost   $g_hostname\" >> /etc/hosts");
        
        if($g_static_ip) {
            emit_line($inst, "echo \"\$ip  \$hostname.\$domain   \$hostname\" >> /etc/hosts");
        }
    }
    
    emit($inst, "\n");
    
    # setup rc.conf
    
    open ($in, "<", $g_rc_conf);
    open ($out, ">", './rc.conf');        
        
    while(my $line = <$in>) {        
        if ($line =~ /^[#\s]*interface=/ and defined($g_interface)) {            
            print $out "interface=$g_interface\n";            
        }
        else {
            print $out $line;
        }
    }
    
    close $in;
    close $out;
    
    open RCFILE, './rc.conf';
    emit_line($inst, "cat > $g_rc_conf << 'EOF'");
    while(<RCFILE>) {
        emit($inst, $_);
    }
    close RCFILE;
    emit_line($inst, 'EOF');            
    unlink('./rc.conf');
   
    # setup hardware clock
        
    if($g_use_localetime) {
        emit_line($inst, "hwclock --systohc --localtime");
    }
    else {
        emit_line($inst, "hwclock --systohc --utc");
    }
   
    # create initial ramdisk
    
    emit_line($inst, "mkinitcpio -p linux");
    
    # install bootloader
    
    if(defined $g_bootloader)
    {
        given($g_bootloader)
        {
            when('grub') {
                emit_line($inst, "grub-install $g_disk");
                emit_line($inst, "cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo");
                emit_line($inst, "grub-mkconfig -o /boot/grub/grub.cfg");
            }
            when('syslinux') {
                emit_line($inst, "/usr/sbin/syslinux-install_update -iam");
            }        
        }
    }
        
    emit_line($inst, "passwd");    
    
    emit_line($inst, "fi");    
    
    close $inst;
    chmod 0755, "$g_install_script";
    
    $viewer->text("Congratulations!\nAn installer has been saved as $g_install_script. You may quit and install Arch with the following command: ./$g_install_script");
}

#=======================================================================
1;