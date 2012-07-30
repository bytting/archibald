#!/usr/bin/perl -w
#=======================================================================
package Arch_Callbacks;

use strict;
use warnings;

sub Menu_Main_Focus {    
}

sub Help_Focus {
    my $this = shift;
    my $info = $this->getobj('info');    
    open FILE, "< stderr.log";
    my @content = <FILE>; close FILE;    
    $info->text(join('', reverse(@content)));
}

sub Configure_Keymap_Focus {
    my $this = shift;
    my $info = $this->getobj('info');
    $info->text('Select a keymap...');
}

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

sub Prep_Hard_Drive_Focus {
    #my $this = shift;
    #my $info = $this->getobj('info');    
}

sub Select_Mirror_Focus {
    #my $this = shift;
    #my $info = $this->getobj('info');    
}

sub Install_System_Focus {
    #my $this = shift;
    #my $info = $this->getobj('info');    
}

sub Configure_System_Focus {
    #my $this = shift;
    #my $info = $this->getobj('info');    
}

sub Reboot_System_Focus {
    #my $this = shift;
    #my $info = $this->getobj('info');    
}

sub Quit_Focus {
    my $this = shift;
    my $info = $this->getobj('info');
    $info->text('Are you sure?');
}
1;