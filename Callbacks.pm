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

#=======================================================================
# Callbacks - Main menu
#=======================================================================
    
sub MM_focus {    
}

#=======================================================================
# Callbacks - Configure keymap
#=======================================================================

sub CK_focus
{
    use vars qw($g_keymap_directory $g_keymap_extension);
    
    my $win = shift;
    my $info = $win->getobj('info');
    my $keymaplist = $win->getobj('keymaplist');    
        
    my ($err, @keymaps) = find_files_deep($g_keymap_directory, $g_keymap_extension);
    if($err) {
        $info->text('No keymaps found');
        return;
    }
    
    foreach (@keymaps) {
        s/^$g_keymap_directory//;
        s/$g_keymap_extension$//;
    }
    
    $keymaplist->values(\@keymaps);
    $info->text('Select a keymap...');
}

sub CK_nav_apply
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $kmlist = $win->getobj('keymaplist');            
    my $km = $kmlist->get();
    
    return unless defined($km);
    
    $km = (split(/\//, $km))[-1];
    
    `loadkeys $km`;
    
    if($?) { $info->text("Loading keymap $km failed. See log for details"); }
    else { $info->text("Keymap $km loaded successfully"); }    
}

#=======================================================================
# Callbacks - Configure network
#=======================================================================

sub CN_focus
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
    $info->text('Configure network...');
}

sub CN_nav_updown
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');        
    my $iflist = $win->getobj('interfacelist');        
    my $iface = $iflist->get();
    if(!defined($iface)) {
        $info->text("You must select an interface first");
        return
    }
    
    $iface =~ /(.*)\s/;
    $iface = $1;    
    my ($op, $val) = (undef, $bbox->get());    
    if($val eq 'enable') { $op = 'up' }
    elsif($val eq 'disable') { $op = 'down' }    
    
    `ip link set $iface $op > /dev/null`;
    
    if($?) { $info->text("The command '$iface $op' failed") }
    else { $info->text("The command '$iface $op' was a success") }        
}

#=======================================================================
# Callbacks - Prepare hard drive
#=======================================================================

sub PHD_focus
{    
    my $win = shift;    
    my $devicelist = $win->getobj('devicelist');
    
    my (@values, %labels);
    my @ipc = `fdisk -l`;    
    
    for (@ipc) {
        if (/^Disk\s+\/dev/) {        
            push @values, "$_";
            $labels{$_} = "$_";
        }
    }
        
    $devicelist->values(\@values);
    $devicelist->labels(\%labels);    
}

sub PHD_nav_format
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $cui = $bbox->parent->parent;
    my $client = $bbox->get();    
    my $devicelist = $bbox->parent->getobj('devicelist');
    my $disk = (split(/\s/, $devicelist->get()))[1];    
    $disk =~ s/:$//;
    
    `which $client`;
    if($?) {
        $info->text("The program $client does not appear to be installed");
        return;
    }
    
    $cui->leave_curses();    
    
    system("$client $disk");    
    
    $cui->reset_curses();
}

#=======================================================================
# Callbacks - Select mount points and filesystem
#=======================================================================

sub SMP_focus
{
    my $win = shift;
    my $info = $win->getobj('info');
    my $devicelist = $win->getobj('devicelist');
    my $partlist = $win->getobj('partlist');
    my $mountlist = $win->getobj('mountlist');
    my $fslist = $win->getobj('fslist');
    
    $partlist->clear_selection();
    $mountlist->clear_selection();
    $fslist->clear_selection();
    
    my %disks;
    my @ipc = `fdisk -l`;    
    
    for (@ipc) {
        if (/^Disk.+bytes$/) {
            /(\/dev\/\w+):.+\s(\d+)\sbytes$/;            
            $disks{$1} = $2;
        }
    }
        
    $devicelist->values(keys %disks);    
    $devicelist->focus;
    $info->text('Select a device...');
}

sub SMP_devicelist_change
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my ($info, $devicelist, $partlist) = ($win->getobj('info'), $win->getobj('devicelist'), $win->getobj('partlist'));    
    my $device = $devicelist->get();
    
    return unless defined($device);    
    
    my @partitions;
    my @ipc = `fdisk -l`;    
        
    for (@ipc) {
        if (/^$device\d+/) {            
            /(\S+)\s/;            
            push @partitions, $1;
        }
    }
    
    $partlist->values(\@partitions);
    $partlist->focus;        
}

sub SMP_devicelist_focus
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    $info->text('Select a device...');
}

sub SMP_partlist_change
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');    
    my $mountlist = $win->getobj('mountlist');
    
    $mountlist->values(['boot', 'swap', 'root', 'home', 'dev', 'var']);
    $mountlist->focus;    
}

sub SMP_partlist_focus
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    $info->text('Select a partition...');
}

sub SMP_mountlist_change
{
    my $bbox = shift;
    my $win = $bbox->parent;    
    my $fslist = $win->getobj('fslist');
    
    $fslist->values(['ext2', 'ext3', 'ext4', 'swap']);
    $fslist->focus;    
}

sub SMP_mountlist_focus
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    $info->text('Select a mount point...');
}

sub SMP_fslist_change
{
    my $bbox = shift;
    my $win = $bbox->parent;    
    my $nav = $win->getobj('nav');
    
    $nav->focus;    
}

sub SMP_fslist_focus
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    $info->text('Select a file system type...');
}
 
sub SMP_nav_focus
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    $info->text('');
}
 
sub SMP_nav_add
{
    use vars qw(@g_partition_table);
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');    
    my ($devicelist, $partlist, $mountlist, $fslist, $parttable) = (
        $win->getobj('devicelist'), $win->getobj('partlist'), $win->getobj('mountlist'), $win->getobj('fslist'), $win->getobj('parttable')
    );                
    
    my $entry = $partlist->get() . ':' . $mountlist->get() . ':' . $fslist->get();
    push @g_partition_table, $entry;
    
    $parttable->values(\@g_partition_table);
    $parttable->draw(0);
    $parttable->focusable(0);
    $devicelist->focus;    
}

sub SMP_nav_apply
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $parttable = $win->getobj('parttable');
    
    if(!@g_partition_table) {
        $info->text('Configuration is empty. Nothing to do...');
        return;
    }
    
    foreach(@g_partition_table) {
        my ($part, $mount, $fs) = split(/:/);
        
        given($fs) {
            when ('ext2') { `mkfs.ext2 $part` }
            when ('ext3') { `mkfs.ext3 $part` }
            when ('ext4') { `mkfs.ext4 $part` }
            when ('swap') { `mkswap $part && swapon $part` }
            default {
               $info->text("Unsupported filesystem found ($fs). See log for details");
               print STDERR "Filesystem $fs not supported\n";
            }
        }        
    }
        
    $info->text('Configuration applied successfully');
}

sub SMP_nav_clear
{
    use vars qw(@partition_table);
    my $bbox = shift;
    my $win = $bbox->parent;
    my ($devicelist, $parttable) = ($win->getobj('devicelist'), $win->getobj('parttable'));
    
    @partition_table = ();
    $parttable->values(\@partition_table);
    $parttable->draw(0);
    $parttable->focusable(0);
    $devicelist->focus;
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
    
    $mirrorlist->values(map { "$_ - $mirrors{$_}" } keys %mirrors);
    $info->text('Select the mirrors you want to enable');
}

sub SM_nav_apply
{
    use vars qw($g_mirrorlist);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my ($info, $mirrorlist) = ($win->getobj('info'), $win->getobj('mirrorlist'));            
    my @selected = $mirrorlist->get();
    my ($url, $found);
        
    open (my $in, "<", $g_mirrorlist);
    open (my $out, ">", $g_mirrorlist . '.tmp');    

    while(my $line = <$in>) {        
        if ($line =~ /^\s*$/) {
            print $out $line;
            next;
        }
        $found = 0;
        foreach(@selected) {
            $_ =~ s/\s.*$//;
            if(index($line, $_) != -1) {
                $found = 1;
                $line =~ s/^[#\s]+//;                
                print $out $line;
                last;
            }
        }
        
        if(!$found) {
            if($line !~ /^#/) { print $out "#$line"; }
            else { print $out $line; }
        }        
    }
    
    close $in;
    close $out;
    
    rename $g_mirrorlist . '.tmp', $g_mirrorlist;
    
    $info->text('mirrorlist generated successfully');
}

#=======================================================================
# Callbacks - Install system
#=======================================================================

sub IS_focus
{       
    my $win = shift;
    my $info = $win->getobj('info');
    my $bootloaderlist = $win->getobj('bootloaderlist');
    
    $bootloaderlist->values(['grub2', 'syslinux']);
}

sub IS_nav_go
{
    use vars qw(@g_partition_table $g_bootloader);
    
    my $win = shift;
    my $info = $win->getobj('info');
    my $bootloaderlist = $win->getobj('bootloaderlist');
        
    if(!@g_partition_table) {
        $info->text('Configuration is empty. Please set up a disk configuration in \'Select mount points and filesystem\' first');
        return;
    }    
    
    $g_bootloader = $bootloaderlist->get();    
    
    if(!defined($g_bootloader)) {
        $info->text('You must select a bootloader first');
        return;
    }
    
    # mount partitions
    my $root_ok = 0;
    foreach(@g_partition_table) {
        my ($part, $mount, $fs) = split(/:/);
        if($mount == 'root') {            
            `mount $part /mnt > /dev/null 2>&1`;
            $root_ok = 1;
        }
    }
    
    if(!$root_ok) {
        $info->text('Configuration has no root. Please set up a root configuration in \'Select mount points and filesystem\' first');
        return;
    }
    
    foreach(@g_partition_table) {
        my ($part, $mount, $fs) = split(/:/);
        
        given($mount) {
            when ('boot') {
                `mkdir -p /mnt/boot > /dev/null 2>&1`;
                `mount $part /mnt/boot > /dev/null 2>&1`;
            }            
            when ('root') {}
            when ('home') {
                `mkdir -p /mnt/home > /dev/null 2>&1`;
                `mount $part /mnt/home > /dev/null 2>&1`;
            }
            when ('dev') {
                `mkdir -p /mnt/dev > /dev/null 2>&1`;
                `mount $part /mnt/dev > /dev/null 2>&1`;
            }
            when ('var') {
                `mkdir -p /mnt/var > /dev/null 2>&1`;
                `mount $part /mnt/var > /dev/null 2>&1`;
            }
            default {
               $info->text("Unsupported mount point found ($mount). See log for details");
               print STDERR "Mount point $mount not supported\n";
            }
        }        
    }
         
    # install
    `pacstrap /mnt base base-devel`;
    
    given($g_bootloader) {
        when('syslinux') { `pacstrap /mnt syslinux` }        
        when('grub2') { `pacstrap /mnt grub-bios` }
        #when('grub2-EFI') { `pacstrap /mnt grub-efi-x86_64` }        
    }
    
    `genfstab -p /mnt >> /mnt/etc/fstab`;
    
    $info->text("Installation was sucessful, now go to \'Configure the new system\' to prepare the system");
}

#=======================================================================
# Callbacks - Configure system
#=======================================================================

sub CS_focus
{
    use vars qw($g_bootloader);
    
    my $win = shift;
    my $info = $win->getobj('info');
    my $hostnameentry = $win->getobj('hostname');
    
    if(!defined($g_bootloader)) {
        $info->text('You must select a bootloader in \'Install base system\' first');
        return;
    }
    
    my $hostname = $hostnameentry->get();
    
    if(!defined($hostname)) {
        $info->text('You must select a hostname first');
        return;
    }
    
    # chroot into system
    `arch-chroot /mnt > /dev/null 2>&1`;
    
    # setup hostname
    `echo $hostname > /etc/hostname`;
    # add hostname to /etc/hosts
    
    # setup vconsole.conf
    
    # setup timezone
    
    # setup locale
    
    # setup hardware clock
    
    # setup kernel modules
    
    # setup daemons
    
    # configure network
    
    # create initial ramdisk
    
    # configure bootloader
    
    # setup root password
    
    # unmount and exit chroot
}

#=======================================================================
# Callbacks - Log
#=======================================================================

sub L_focus
{
    my $win = shift;
    my $info = $win->getobj('viewer');
    my $nav = $win->getobj('nav');
    
    open FILE, "< stderr.log";
    my @content = <FILE>; close FILE;    
    $info->text(join('', reverse(@content)));
    $nav->focus;
}

#=======================================================================
# Callbacks - Reboot
#=======================================================================

sub RS_focus
{
    #my $this = shift;
    #my $info = $this->getobj('info');    
}

#=======================================================================
# Callbacks - Quit
#=======================================================================

sub Q_focus
{
    my $win = shift;
    my $info = $win->getobj('info');
    
    $info->text('Are you sure?');
}

#=======================================================================
1;