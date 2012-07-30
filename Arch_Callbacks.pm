#!/usr/bin/perl -w
#=======================================================================

package Arch_Callbacks;

use strict;
use warnings;
use File::Basename;
use Arch_Common;

#=======================================================================
# Callbacks - Main menu
#=======================================================================
    
sub Menu_Main_Focus {    
}

#=======================================================================
# Callbacks - Configure keymap
#=======================================================================

sub Configure_Keymap_Focus {
    my $this = shift;
    my $info = $this->getobj('info');
    $info->text('Select a keymap...');
}

sub Configure_Keymap_Browse {
    my $bbox = shift;
    my $win = $bbox->parent;
    my $cui = $win->parent;
    
    my $file = $cui->filebrowser(
        -path => $Arch_Common::keymap_directory, 
        -show_hidden => 0, 
        -editfilename => 0, 
        -mask => $Arch_Common::keymap_mask,
        -title => "Select a keymap file", -bfg => "red", -tfg => "green");	
    
    my $info = $win->getobj('info');
    
    if(!defined($file)) { $info->text("No keymap selected"); return; }        
            
    my ($keymap, $dir, $ext) = fileparse($file, '\..*');		
    
    `loadkeys $keymap > /dev/null`;
    
    if($?) { $info->text("Unable to load keymap $keymap") }
    else { $info->text("Selected keymap $keymap") }    
}

#=======================================================================
# Callbacks - Configure network
#=======================================================================

sub Configure_Network_Focus {
    my $this = shift;
    my $info = $this->getobj('info');    
    $info->text('Configure network...');
    
    my $iflist = $this->getobj('interfacelist');

    my @values;
    my %labels;
    my $cnt = 0;
    my @ipc = `ip addr`;
    for (@ipc) {
        if ( /^(\d+):\s*(\w+).*state\s(\w+)/ ) {        
            my ($nr, $if, $state) = ($1, $2, $3);
            if($if eq 'lo') {
                next;
            }
            push @values, "$if ($state)";
            $labels{++$cnt} = "$if ($state)";
        }
    }
        
    $iflist->values(\@values);
    $iflist->labels(\%labels);        
}

sub Configure_Network_UpDown {
    my $bbox = shift;
    my $win = $bbox->parent;
    my $info = $win->getobj('info');        
    my $iflist = $win->getobj('interfacelist');        
    my $iface = $iflist->get();
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
    #my $this = shift;
    #my $info = $this->getobj('info');    
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
    my $this = shift;
    my $info = $this->getobj('editor');    
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
    my $this = shift;
    my $info = $this->getobj('info');
    $info->text('Are you sure?');
}

#=======================================================================
1;