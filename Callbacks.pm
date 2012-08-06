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
            push @disks, $_;
        }
    }    
        
    $devicelist->values(@disks);    
    $devicelist->focus;
    $info->text('Select a device...');
}

sub SMP_devicelist_change
{
    my $bbox = shift;
    my $win = $bbox->parent;    
    my $mountlist = $win->getobj('mountlist');
    
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
    use vars qw(@g_partition_table $g_disk);
    
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');    
    my ($devicelist, $mountlist, $fslist, $partsize, $parttable) = (
        $win->getobj('devicelist'), $win->getobj('mountlist'), $win->getobj('fslist'), $win->getobj('partsize'), $win->getobj('parttable')
    );                
    
    $g_disk = "/dev/" . $devicelist->get();
    my $entry = $g_disk . ':' . $mountlist->get() . ':' . $fslist->get() . ':' . $partsize->get();
    
    push @g_partition_table, $entry;
    
    $parttable->values(\@g_partition_table);
    $parttable->draw(0);     
    $devicelist->focus;
    
    $info->text('Entry added...');
}

sub SMP_nav_clear
{
    use vars qw(@partition_table);
    my $bbox = shift;
    my $win = $bbox->parent;
    my ($devicelist, $parttable) = ($win->getobj('devicelist'), $win->getobj('parttable'));
    my ($mountlist, $fslist) = ($win->getobj('mountlist'), $win->getobj('fslist'));
        
    $devicelist->clear_selection();
    $mountlist->clear_selection();
    $fslist->clear_selection();
    @partition_table = ();
    $parttable->values(\@partition_table);
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
    #my $this = shift;
    #my $info = $this->getobj('info');    
}

sub IS_nav_make_install
{
    use vars qw($g_keymap $g_bootloader $g_wirelesstools @g_partition_table @g_mirrors
    $g_timezone $g_localetime @g_locales $g_locale_lang $g_hostname $g_interface $g_static_ip $g_ip
    $g_domain $g_disk $g_rc_conf $g_locale_default);
    
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
                
            }
            
            if(!defined($g_domain)) {
                
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
    
    my $last_mount;
    open INST, ">install.sh";
    
    print INST "#!/bin/bash\n\n";
    
    print INST "parted -s $g_disk mktable gpt\n\n";
    
    #max=$(( $(cat $g_disk/size) * 512 / 1024 / 1024 - 1 ))
    
    foreach(@g_partition_table) {
        my ($dsk, $mount, $fs, $size) = split /:/;
        if(defined($last_mount)) {
            print INST "$mount=\$((\$$last_mount + $size))\n";
            print INST "parted $g_disk unit MiB mkpart primary \$$last_mount \$$mount\n";
        }
        else {
            print INST "$mount=\$((1 + $size))\n";
            print INST "parted $g_disk unit MiB mkpart primary 1 \$$mount\n";
        }        
        $last_mount = $mount;
    }
    
    print INST "\n";
    
    my $partnr = 1;
    foreach(@g_partition_table) {
        my ($dsk, $mount, $fs, $size) = split /:/;
        given($fs) {
            when('ext2') {
                print INST "mkfs.ext2 $g_disk$partnr\n";
            }
            when('ext3') {
                print INST "mkfs.ext3 $g_disk$partnr\n";
            }
            when('ext4') {
                print INST "mkfs.ext4 $g_disk$partnr\n";
            }
            when('swap') {
                print INST "mkswap $g_disk$partnr\n";
                print INST "swapon $g_disk$partnr\n";
            }
        }
        
        if($mount eq 'root') {
            print INST "mount $g_disk /mnt\n";
        }
        $partnr++;
    }
    
    print INST "\n";    
    
    $partnr = 1;
    foreach(@g_partition_table) {
        my ($dsk, $mount, $fs, $size) = split /:/;
        given($mount) {
            when('boot') {
                print INST "mkdir /mnt/boot\n";
                print INST "mount $g_disk$partnr /mnt/boot\n";
            }
            when('home') {
                print INST "mkdir /mnt/home\n";
                print INST "mount $g_disk$partnr /mnt/home\n";
            }
            when('var') {
                print INST "mkdir /mnt/var\n";
                print INST "mount $g_disk$partnr /mnt/var\n";
            }
            when('dev') {
                print INST "mkdir /mnt/dev\n";
                print INST "mount $g_disk$partnr /mnt/dev\n";
            }
        }
        $partnr++;
    }
    
    print INST "\n";
    
    if(@g_mirrors) {
        open (my $in, "<", $g_mirrorlist);
        open (my $out, ">", "./mirrorlist");    
    
        my $found = 0;
        while(my $line = <$in>) {        
            if ($line =~ /^\s*$/) {
                print $out $line;
                next;
            }
            $found = 0;
            foreach(@g_mirrors) {
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
                
        open MIRRORFILE, './mirrorlist';
        print INST "cat>$g_mirrorlist <<EOF\n";
        while(<MIRRORFILE>) {
            print INST $_;
        }
        close MIRRORFILE;
        print INST "EOF\n\n";
        unlink('./mirrorlist');
    }
    
    print INST "\n";
    
    print INST "pacstrap /mnt base base-devel\n";
    
    if($g_wirelesstools) {
        print INST "pacstrap /mnt wireless_tools netcfg wpa_supplicant wpa_actiond\n";
    }
    
    given($g_bootloader) {
        when('grub2') {
            print INST "pacstrap /mnt grub-bios\n";
        }
        when('syslinux') {
            print INST "pacstrap /mnt syslinux\n";
        }
    }
    
    print INST "\n";
    
    print INST "genfstab -p /mnt >> /mnt/etc/fstab\n";    
    print INST "arch-chroot /mnt\n";

    print INST "\n";
    
    # setup vconsole.conf
    
    print INST "echo \"KEYMAP=$g_keymap\" > /etc/vconsole.conf\n";
    print INST "echo \"FONT=\" >> /etc/vconsole.conf\n";
    print INST "echo \"FONT_MAP=\" >> /etc/vconsole.conf\n";
    
    print INST "\n";
    
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
    
    print INST "\n";
    
    open LOCFILE, './locale.gen';
    print INST "cat>$g_locale_gen<<EOF\n";
    while(<LOCFILE>) {
        print INST $_;
    }
    close LOCFILE;
    print INST "EOF\n\n";            
    unlink('./locale.gen');
    
    print INST "locale-gen > /dev/null 2>&1\n";
    
    my $locale_lang_stripped = $g_locale_lang;
    $locale_lang_stripped =~ s/\s+.*//;
        
    print INST "echo \"LANG=$locale_lang_stripped\" > /etc/locale.conf\n";
        
    # setup hostname/hosts
    
    print INST "echo \"$g_hostname\" > /etc/hostname\n";
    
    print INST "echo \"127.0.0.1    localhost.localdomain   localhost   $g_hostname\" > /etc/hosts\n";
    print INST "echo \"::1          localhost.localdomain   localhost   $g_hostname\" >> /etc/hosts\n";
    
    if($g_static_ip) {
        print INST "echo \"\$ip  \$hostname.\$domain   \$hostname\" >> /etc/hosts\n";
    }
    
    # setup rc.conf
    
    open (my $rcin, "<", $g_rc_conf);
    open (my $rcout, ">", './rc.conf');        
    
    while(my $line = <$rcin>) {        
        if ($line =~ /^interface=/) {            
            print $rcout "$line$g_interface"; # FIXME does interface already exists?
        }
        else {
            print $rcout $line;
        }
    }
    
    close $rcin;
    close $rcout;
    
    open RCFILE, './rc.conf';
    print INST "cat>$g_rc_conf <<EOF\n";
    while(<RCFILE>) {
        print INST $_;
    }
    close RCFILE;
    print INST "EOF\n\n";            
    unlink('./rc.conf');
   
    # setup hardware clock
        
    if($g_localetime) {
        print INST "hwclock --systohc --localtime\n";
    }
    else {
        print INST "hwclock --systohc --utc\n";
    }
   
    # create initial ramdisk
    print INST "mkinitcpio -p linux\n";
    
    # configure bootloader
    
    given($g_bootloader) {
        when('syslinux') {
            print INST "/usr/sbin/syslinux-install_update -iam\n";
        }        
        when('grub2') {
            print INST "grub-install $g_disk\n";
            print INST "cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo\n";
            print INST "grub-mkconfig -o /boot/grub/grub.cfg\n";
        }        
    }    
        
    print INST "passwd\n";
    
    close INST;
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