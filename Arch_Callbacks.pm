#!/usr/bin/perl -w
#=======================================================================

package Arch_Callbacks;

use strict;
use warnings;
use File::Basename;
use Arch_Common;
use Arch_Functions;

#=======================================================================
# Callbacks - Main menu
#=======================================================================
    
sub Menu_Main_Focus {    
}

#=======================================================================
# Callbacks - Configure keymap
#=======================================================================

sub Configure_Keymap_Focus {
    my $win = shift;
    my $info = $win->getobj('info');
    my $kmlist = $win->getobj('keymaplist');    
    $info->text('Select a keymap...');
    
    my @kmlist;
    my @keymaps = Arch_Functions::get_files_from($Arch_Common::keymap_directory, $Arch_Common::keymap_extension);
    foreach (@keymaps) {
        s/^$Arch_Common::keymap_directory//;
        s/$Arch_Common::keymap_extension$//;
    }
    $kmlist->values(\@keymaps);    
}

sub Configure_Keymap_Apply {
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');
    my $kmlist = $win->getobj('keymaplist');            
    my $km = $kmlist->get();
    $km = (split(/\//, $km))[-1];
    `loadkeys $km`;
    if($?) {
        $info->text("Loading keymap $km failed. See log for details");
    }
    else {
        $info->text("Keymap $km loaded successfully");    
    }    
}

#=======================================================================
# Callbacks - Configure network
#=======================================================================

sub Configure_Network_Focus {
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

sub Configure_Network_UpDown {
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

sub Prep_Hard_Drive_Focus {    
    my $win = shift;    
    my $dm = $win->getobj('devmenu');
    
    my (@values, %labels);
    my @ipc = `fdisk -l`;    
    
    for (@ipc) {
        if (/^Disk\s+\/dev/) {        
            push @values, "$_";
            $labels{$_} = "$_";
        }
    }
        
    $dm->values(\@values);
    $dm->labels(\%labels);    
}

sub Prep_Hard_Drive_Cfdisk {
    my $bbox = shift;
    my $cui = $bbox->parent->parent;
    my $dm = $bbox->parent->getobj('devmenu');
    my $disk = (split(/\s/, $dm->get()))[1];
    $disk =~ s/:$//;    
    
    $cui->leave_curses();    
    system("cfdisk $disk");    
    $cui->reset_curses();
}

#=======================================================================
# Callbacks - Select mount points and filesystem
#=======================================================================

sub Select_Mount_Points_Focus {
    my $win = shift;
    my $info = $win->getobj('info');
    my $devbox = $win->getobj('devmenu');    
    
    $info->text('Select a device...');
    
    my %disks;
    my @ipc = `fdisk -l`;    
    
    for (@ipc) {
        if (/^Disk.+bytes$/) {
            /(\/dev\/\w+):.+\s(\d+)\sbytes$/;            
            $disks{$1} = $2;
        }
    }
        
    $devbox->values(keys %disks);    
}

sub Select_Mount_Points_SelectDevice {
    my $bbox = shift;
    my $win = $bbox->parent;
    my ($info, $devmenu, $partmenu) = ($win->getobj('info'), $win->getobj('devmenu'), $win->getobj('partmenu'));    
    my $dev = $devmenu->get();
    return unless defined($dev);
    
    $info->text('Select a partition...');
    
    my @partitions;
    my @ipc = `fdisk -l`;    
        
    for (@ipc) {
        if (/^$dev\d+/) {            
            /(\S+)\s/;            
            push @partitions, $1;
        }
    }
    
    $partmenu->values(\@partitions);
    $partmenu->focus;
}

sub Select_Mount_Points_SelectPartition {
    my $bbox = shift;
    my $win = $bbox->parent;
    my $mpoints = $win->getobj('mountmenu');
    $mpoints->values(['boot', 'swap', 'root', 'home', 'dev', 'var']);
    $mpoints->focus;
}

sub Select_Mount_Points_SelectMountPoint {
    my $bbox = shift;
    my $win = $bbox->parent;
    my $fsmenu = $win->getobj('fsmenu');
    $fsmenu->values(['ext2', 'ext3', 'ext4', 'swap']);
    $fsmenu->focus;
}

sub Select_Mount_Points_SelectFS {
    my $bbox = shift;
    my $win = $bbox->parent;
    my $navmenu = $win->getobj('navmenu');
    $navmenu->focus;
}

sub Select_Mount_Points_Apply {
    my $bbox = shift;
    my $win = $bbox->parent;
    my $devmenu = $win->getobj('devmenu');
    my $partmenu = $win->getobj('partmenu');
    my $mountmenu = $win->getobj('mountmenu');
    my $fsmenu = $win->getobj('fsmenu');
    
    my $mountpoints = $win->getobj('mountpoints');
        
    my $entry = $partmenu->get() . ':' . $mountmenu->get() . ':' . $fsmenu->get();
    push @Arch_Common::partition_table, $entry;
    
    $mountpoints->values(\@Arch_Common::partition_table);
    $mountpoints->draw(0);
    $mountpoints->focusable(0);
    $devmenu->focus;
}

sub Select_Mount_Points_Write {
    # Write Arch_Common::partition_table to disk...
}

sub Select_Mount_Points_Clear {
    my $bbox = shift;
    my $win = $bbox->parent;
    my $devmenu = $win->getobj('devmenu');
    my $mountpoints = $win->getobj('mountpoints');
    @Arch_Common::partition_table = ();
    $mountpoints->values(\@Arch_Common::partition_table);
    $mountpoints->draw(0);
    $mountpoints->focusable(0);
    $devmenu->focus;
}

#=======================================================================
# Callbacks - Select mirror
#=======================================================================

sub Select_Mirror_Focus {
    #my $this = shift;
    #my $info = $this->getobj('info');    
}

#=======================================================================
# Callbacks - Install system
#=======================================================================

sub Install_System_Focus {
    #my $this = shift;
    #my $info = $this->getobj('info');    
}

#=======================================================================
# Callbacks - Configure system
#=======================================================================

sub Configure_System_Focus {
    #my $this = shift;
    #my $info = $this->getobj('info');    
}

#=======================================================================
# Callbacks - Log
#=======================================================================

sub Log_Focus {
    my $win = shift;
    my $info = $win->getobj('editor');    
    open FILE, "< stderr.log";
    my @content = <FILE>; close FILE;    
    $info->text(join('', reverse(@content)));
}

#=======================================================================
# Callbacks - Reboot
#=======================================================================

sub Reboot_System_Focus {
    #my $this = shift;
    #my $info = $this->getobj('info');    
}

#=======================================================================
# Callbacks - Quit
#=======================================================================

sub Quit_Focus {
    my $win = shift;
    my $info = $win->getobj('info');
    $info->text('Are you sure?');
}

#=======================================================================
1;