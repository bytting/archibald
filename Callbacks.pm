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
    use vars qw($g_keymap);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $kmlist = $win->getobj('keymaplist');            
    my $km = $kmlist->get();
    
    return unless defined($km);
    
    $g_keymap = (split(/\//, $km))[-1];
    
    
    
    `loadkeys $g_keymap`;
    
    if($?) { $info->text("Loading keymap $g_keymap failed. See log for details"); }
    else { $info->text("Keymap $g_keymap loaded successfully"); }    
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
# Callbacks - Select mount points and filesystem
#=======================================================================

sub SMP_focus
{
    use vars qw(%g_disks @g_mountpoints);
    
    my $win = shift;
    my $info = $win->getobj('info');
    my $devicelist = $win->getobj('devicelist');    
    my $mountlist = $win->getobj('mountlist');
    my $fslist = $win->getobj('fslist');    
    
    $mountlist->clear_selection();
    $fslist->clear_selection();
    
    my (@sd_disks, @hd_disks, @disks);
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
        
    $devicelist->values(keys %g_disks);
    $mountlist->values(\@g_mountpoints);
    $devicelist->focus;
    $info->text('Select a device...');
}

sub SMP_devicelist_change
{
    use vars qw(%g_disks @g_partition_table);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $devicelist = $win->getobj('devicelist');
    my $remsize = $win->getobj('remsize');
    my $mountlist = $win->getobj('mountlist');
    
    my $dev = $devicelist->get();
    my $siz = $g_disks{$dev};
    my $tmp;
    foreach(@g_partition_table) {
        $tmp = (split(/:/, $_))[-1];
        $siz -= $tmp;
    }
    
    $remsize->text($siz);
    
    $mountlist->focus;    
}

sub SMP_devicelist_focus
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    $info->text('Select a device...');
}

sub SMP_mountlist_change
{
    my $bbox = shift;
    my $win = $bbox->parent;    
    my $fslist = $win->getobj('fslist');
    
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
    my $partsize = $win->getobj('partsize');
        
    $partsize->focus;    
}

sub SMP_fslist_focus
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    $info->text('Select a file system type...');
}
 
sub SMP_partsize_focus
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    
    $info->text('Enter a partition size in MB...');
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
    use vars qw(@g_partition_table $g_disk %g_disks @g_mountpoints);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $remsize = $win->getobj('remsize');    
    my ($devicelist, $mountlist, $fslist, $partsize, $parttable) = (
        $win->getobj('devicelist'), $win->getobj('mountlist'), $win->getobj('fslist'), $win->getobj('partsize'), $win->getobj('parttable')
    );                
    
    my $dev = $devicelist->get();
    my $dev_path = "/dev/$dev";
    if(defined($g_disk)) {
        if($dev_path ne $g_disk) {
            $info->text("Only one device can be used ($g_disk chosen)");
            return;
        }
    }    
    
    my $siz = $g_disks{$dev};
    my $tmp;
    foreach(@g_partition_table) {
        $tmp = (split(/:/, $_))[-1];
        $siz -= $tmp;
    }
    
    my $new_size = $partsize->get();
    if($siz - $new_size < 0) {
        $info->text("Not enough space on $g_disk");
        return;
    }    
    
    $remsize->text($siz - $new_size);
    
    $g_disk = "/dev/" . $devicelist->get();
    my $entry = $g_disk . ':' . $mountlist->get() . ':' . $fslist->get() . ':' . $new_size;
    
    push @g_partition_table, $entry;
        
    my $item = $mountlist->get();
    @g_mountpoints = grep { $_ ne $item } @g_mountpoints;
    $mountlist->values(\@g_mountpoints);
    
    $parttable->values(\@g_partition_table);
    
    $fslist->clear_selection();
    $partsize->text('');
    
    $parttable->draw(0);     
    $devicelist->focus;
    
    $info->text('Entry added...');
}

sub SMP_nav_clear
{
    use vars qw(@g_partition_table);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my ($devicelist, $parttable) = ($win->getobj('devicelist'), $win->getobj('parttable'));
    my ($mountlist, $fslist) = ($win->getobj('mountlist'), $win->getobj('fslist'));
    my $partsize = $win->getobj('partsize');
    my $remsize = $win->getobj('remsize');
        
    $devicelist->clear_selection();
    $mountlist->clear_selection();
    @g_mountpoints = ('boot', 'root', 'swap', 'home', 'var', 'dev');
    $mountlist->values(\@g_mountpoints);
    $fslist->clear_selection();
    $partsize->text('');
    $remsize->text('');
    @g_partition_table = ();    
    $parttable->values(\@g_partition_table);
    $parttable->draw(0);    
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
    
    $mirrorlist->values(map { "$mirrors{$_} - $_" } keys %mirrors);    
}

sub SM_nav_apply
{
    use vars qw($g_mirrorlist @g_mirrors);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my ($info, $mirrorlist) = ($win->getobj('info'), $win->getobj('mirrorlist'));            
    @g_mirrors = $mirrorlist->get();
    
    $info->text('Mirror selection applied');
}

#=======================================================================
# Callbacks - Select packages
#=======================================================================

sub SP_focus
{       
    my $win = shift;
    my $info = $win->getobj('info');
    my $bootloaderlist = $win->getobj('bootloaderlist');
    
    $bootloaderlist->values(['grub2', 'syslinux']);
}

sub SP_nav_apply
{
    use vars qw($g_bootloader $g_wirelesstools);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $bootloaderlist = $win->getobj('bootloaderlist');
    my $wirelesstoolscb = $win->getobj('wirelesstoolscb');
    
    $g_bootloader = $bootloaderlist->get();
    $g_wirelesstools = $wirelesstoolscb->get();    
    
    $info->text("Package selection applied");
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
    my $localelist = $win->getobj('localelist');
    my $localelist_lang = $win->getobj('localelist_lang');
    
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
}

sub CS_nav_apply
{
    use vars qw($g_timezone @g_locales $g_locale_lang $g_localetime);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $cui = $win->parent;
    my $info = $win->getobj('info');    
    my $timezonelist = $win->getobj('timezonelist');
    my $localelist = $win->getobj('localelist');
    my $localelist_lang = $win->getobj('localelist_lang');
    my $localetimecb = $win->getobj('localetimecb');    
        
    $g_timezone = $timezonelist->get();
    @g_locales = $localelist->get();
    $g_locale_lang = $localelist_lang->get();
    $g_locale_lang =~ s/\s+.*//;
    chomp($g_locale_lang);
    $g_localetime = $localetimecb->get();
    
    $info->text('System configuration applied');
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

sub CNET_staticip_changed
{
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');        
    my $ipentry = $win->getobj('ipentry');
    my $domainentry = $win->getobj('domainentry');
    
    
    my $state = $bbox->get();
    if($state) {
        $ipentry->title('IP Address *');
        $domainentry->title('Domain *');
    }
    else {
        $ipentry->title('IP Address');
        $domainentry->title('Domain');
    }
}

sub CNET_nav_apply
{
    use vars qw($g_hostname $g_interface $g_static_ip $g_ip $g_domain);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');    
    my $hostnameentry = $win->getobj('hostnameentry');
    my $staticipcb = $win->getobj('staticipcb');
    my $interfacelist = $win->getobj('interfacelist');
    my $ipentry = $win->getobj('ipentry');
    my $domainentry = $win->getobj('domainentry');
    
    $g_hostname = $hostnameentry->get();
    $g_interface = $interfacelist->get();    
    $g_interface =~ s/\s+.*$//;    
    $g_static_ip = $staticipcb->get();    
    $g_ip = $ipentry->get();
    $g_domain = $domainentry->get();
    
    $info->text('Networking configuration applied');
}

#=======================================================================
# Callbacks - Install
#=======================================================================

sub IS_focus
{
    my $win = shift;    
    my $nav = $win->getobj('nav');
        
    $nav->focus;
}

sub IS_nav_make_install
{
    use vars qw($g_keymap $g_bootloader $g_wirelesstools @g_partition_table @g_mirrors
    $g_timezone $g_localetime @g_locales $g_locale_lang $g_hostname $g_interface $g_static_ip $g_ip
    $g_domain $g_disk $g_rc_conf $g_locale_default $g_install_script);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $viewer = $win->getobj('viewer');

    # make sure all required variables are set
    
    if(!defined($g_disk)) {
        $viewer->text('Disk undefined');
        return;
    }
    
    if(!defined($g_keymap)) {
        $viewer->text('Keymap undefined');
        return;
    }
    
    if(!defined($g_bootloader)) {
        $viewer->text('Bootloader undefined');
        return;
    }    
    
    if(!@g_partition_table) {
        $viewer->text('Partition table is empty');
        return;
    }    
    
    if(!defined($g_timezone)) {
        
    }
    
    if(!@g_locales) {
        $viewer->text('No locales enabled');
        return;
    }
    
    if(!defined($g_locale_lang)) {
        $viewer->text('Language locale not set');
        return;
    }
    
    if(defined($g_interface)) {
        
        if(!defined($g_hostname)) {
            $viewer->text('Hostname not set');
            return;
        }
        
        if($g_static_ip) {
            
            if(!defined($g_ip)) {
                $viewer->text('IP address not set for static interface');
                return;
            }
            
            if(!defined($g_domain)) {
                $viewer->text('Domain not set for static interface');
                return;
            }
        }
    }
    
    # make sure the root partition is set
    
    my $root_found = 0;
    foreach(@g_partition_table) {
        my ($dsk, $mount, $fs, $size) = split /:/;
        if($mount eq 'root') { $root_found = 1; }
    }
    
    if(!$root_found) {
        $viewer->text('No root partition found');
        return;
    }
    
    # create and generate the installer script
        
    open my $inst, ">$g_install_script";    
    emit_bash($inst, "#!/bin/bash");    
    emit_bash($inst, "if [ \$1 != \"--configure\"]; then # This part runs before chroot jail");    
    emit_bash_with_check($inst, "parted -s $g_disk mktable gpt", "parted mktable successful", "parted mktable failed");    
    
    my $last_mount;    
    foreach(@g_partition_table) {
        my ($dsk, $mount, $fs, $size) = split /:/;
        if(defined($last_mount)) {
            emit_bash($inst, "$mount=\$((\$$last_mount + $size))");
            emit_bash_with_check($inst, "parted $g_disk unit MiB mkpart primary \$$last_mount \$$mount", "parted mkpart successful", "parted mkpart failed");
        }
        else {
            emit_bash($inst, "$mount=\$((1 + $size))");
            emit_bash_with_check($inst, "parted $g_disk unit MiB mkpart primary 1 \$$mount", "parted mkpart successful", "parted mkpart failed");
        }        
        $last_mount = $mount;
    }
    
    emit_bash($inst, "\n");
    
    my $partnr = 1;
    foreach(@g_partition_table) {
        my ($dsk, $mount, $fs, $size) = split /:/;
        given($fs) {
            when('ext2') {
                emit_bash_with_check($inst, "mkfs.ext2 $g_disk$partnr", "mkfs.ext2 successful", "mkfs.ext2 failed");
            }
            when('ext3') {
                emit_bash_with_check($inst, "mkfs.ext3 $g_disk$partnr", "mkfs.ext3 successful", "mkfs.ext3 failed");
            }
            when('ext4') {
                emit_bash_with_check($inst, "mkfs.ext4 $g_disk$partnr", "mkfs.ext4 successful", "mkfs.ext4 failed");
            }
            when('swap') {
                emit_bash_with_check($inst, "mkswap $g_disk$partnr", "mkswap successful", "mkswap failed");
                emit_bash_with_check($inst, "swapon $g_disk$partnr", "swapon successful", "swapon failed");
            }
        }
        
        if($mount eq 'root') {
            emit_bash_with_check($inst, "mount $g_disk$partnr /mnt", "mount successful", "mount failed");
        }
        $partnr++;
    }
    
    emit_bash($inst, "\n");    
    
    $partnr = 1;
    foreach(@g_partition_table) {
        my ($dsk, $mount, $fs, $size) = split /:/;
        given($mount) {
            when('boot') {
                emit_bash_with_check($inst, "mkdir /mnt/boot", "mkdir sucessful", "mkdir failed");
                emit_bash_with_check($inst, "mount $g_disk$partnr /mnt/boot", "mount successful", "mount failed");
            }
            when('home') {
                emit_bash_with_check($inst, "mkdir /mnt/home", "mkdir sucessful", "mkdir failed");
                emit_bash_with_check($inst, "mount $g_disk$partnr /mnt/home", "mount successful", "mount failed");
            }
            when('var') {
                emit_bash_with_check($inst, "mkdir /mnt/var", "mkdir sucessful", "mkdir failed");
                emit_bash_with_check($inst, "mount $g_disk$partnr /mnt/var", "mount successful", "mount failed");
            }
            when('dev') {
                emit_bash_with_check($inst, "mkdir /mnt/dev", "mkdir sucessful", "mkdir failed");
                emit_bash_with_check($inst, "mount $g_disk$partnr /mnt/dev", "mount successful", "mount failed");
            }
        }
        $partnr++;
    }
    
    emit_bash($inst, "\n");    
    
    emit_bash_with_check($inst, "pacstrap /mnt base base-devel", "pacstrap successful", "pacstrap failed");
    
    if($g_wirelesstools) {
        emit_bash_with_check($inst, "pacstrap /mnt wireless_tools netcfg wpa_supplicant wpa_actiond", "pacstrap successful", "pacstrap failed");
    }
    
    given($g_bootloader) {
        when('grub2') {
            emit_bash_with_check($inst, "pacstrap /mnt grub-bios", "pacstrap successful", "pacstrap failed");
        }
        when('syslinux') {
            emit_bash_with_check($inst, "pacstrap /mnt syslinux", "pacstrap successful", "pacstrap failed");
        }
    }
    
    emit_bash($inst, "\n");
    
    emit_bash_with_check($inst, "genfstab -p /mnt >> /mnt/etc/fstab", "genfstab successful", "genfstab failed");
    
    emit_bash($inst, "\n");
    
    emit_bash_with_check($inst, "mv $g_install_script /mnt/$g_install_script", "mv successful", "mv failed");
    emit_bash_with_check($inst, "arch-chroot /mnt /$g_install_script --configure", "arch-chroot successful", "arch-chroot failed");
    
    emit_bash($inst, "\n");    
    emit_bash($inst, "echo \"Installation was a success\"");
    
    emit_bash($inst, "\n\nelse # This part runs in chroot jail\n\n");    
    
    # setup vconsole.conf
    
    emit_bash($inst, "echo \"KEYMAP=$g_keymap\" > /etc/vconsole.conf");
    emit_bash($inst, "echo \"FONT=\" >> /etc/vconsole.conf");
    emit_bash($inst, "echo \"FONT_MAP=\" >> /etc/vconsole.conf");
    
    emit_bash($inst, "\n");        
    
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
                if($line !~ /^#/) { print $out "#$line"; }
                else { print $out $line; }
            }        
        }
        
        close $in;
        close $out;
                
        open MIRRORFILE, './mirrorlist';
        emit_bash($inst, "cat>$g_mirrorlist <<EOF");
        while(<MIRRORFILE>) {
            emit($inst, $_);
        }
        close MIRRORFILE;
        emit_bash($inst, "EOF");
        unlink('./mirrorlist');
    }
    
    # setup locale
    
    open (my $in, "<", $g_locale_gen);
    open (my $out, ">", './locale.gen');    
    
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
    
    emit_bash($inst, "\n");
    
    open LOCFILE, './locale.gen';
    emit_bash($inst, "cat>$g_locale_gen<<EOF");
    while(<LOCFILE>) {
        emit($inst, $_);
    }
    close LOCFILE;
    emit_bash($inst, "EOF");            
    unlink('./locale.gen');
    
    emit_bash_with_check($inst, "locale-gen > /dev/null 2>&1", "locale-gen successful", "locale-gen failed");
    
    emit_bash($inst, "\n");
            
    emit_bash($inst, "echo \"LANG=$g_locale_lang\" > /etc/locale.conf");
        
    # setup hostname/hosts
    
    if(defined($g_hostname)) {
        emit_bash($inst, "echo \"$g_hostname\" > /etc/hostname");
        
        emit_bash($inst, "echo \"127.0.0.1    localhost.localdomain   localhost   $g_hostname\" > /etc/hosts");
        emit_bash($inst, "echo \"::1          localhost.localdomain   localhost   $g_hostname\" >> /etc/hosts");
        
        if($g_static_ip) {
            emit_bash($inst, "echo \"\$ip  \$hostname.\$domain   \$hostname\" >> /etc/hosts");
        }
    }
    
    emit_bash($inst, "\n");
    
    # setup rc.conf
    
    open (my $rcin, "<", $g_rc_conf);
    open (my $rcout, ">", './rc.conf');        
    
    while(my $line = <$rcin>) {        
        if ($line =~ /^interface=/ and defined($g_interface)) {            
            print $rcout "interface=$g_interface\n";
        }
        else {
            print $rcout $line;
        }
    }
    
    close $rcin;
    close $rcout;
    
    open RCFILE, './rc.conf';
    emit_bash($inst, "cat>$g_rc_conf <<EOF");
    while(<RCFILE>) {
        emit($inst, $_);
    }
    close RCFILE;
    emit_bash($inst, "EOF");            
    unlink('./rc.conf');
   
    # setup hardware clock
        
    if($g_localetime) {
        emit_bash_with_check($inst, "hwclock --systohc --localtime", "hwclock successful", "hwclock failed");
    }
    else {
        emit_bash_with_check($inst, "hwclock --systohc --utc", "hwclock successful", "hwclock failed");
    }
   
    # create initial ramdisk
    emit_bash_with_check($inst, "mkinitcpio -p linux", "mkinitcpio successful", "mkinitcpio failed");
    
    # configure bootloader
    
    given($g_bootloader) {
        when('syslinux') {
            emit_bash_with_check($inst, "/usr/sbin/syslinux-install_update -iam", "syslinux-install_update successful", "syslinux-install_update failed");
        }        
        when('grub2') {
            emit_bash_with_check($inst, "grub-install $g_disk", "grub-install successful", "grub-install failed");
            emit_bash($inst, "cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo");
            emit_bash_with_check($inst, "grub-mkconfig -o /boot/grub/grub.cfg", "grub-mkconfig successful", "grub-mkconfig failed");
        }        
    }    
        
    emit_bash($inst, "passwd");    
    
    emit_bash($inst, "fi");    
    
    close $inst;
    chmod 0755, "$g_install_script";
    
    $viewer->text("Congratulations!\nAn installer has been saved in current working directory as $g_install_script. You may quit and install Arch with the following command: ./$g_install_script");
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
# Callbacks - Quit
#=======================================================================

sub Q_focus
{    
}

#=======================================================================
1;