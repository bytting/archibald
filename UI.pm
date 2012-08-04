#!/usr/bin/env perl
#=======================================================================
# Arch_UI.pm - UI for archibald.pl
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

package UI;

use strict;
use warnings;
use Curses::UI;
require Callbacks;

my $cui;
my %win = ();
my %win_args = (-border => 1, -titlereverse => 0, -pad => 1, -ipad => 1, -bfg => 'red', -tfg => 'green' );

sub handler_quit()
{
    $cui->mainloopExit() if defined($cui);
    exit(0);
}

sub run()
{        
    $cui = Curses::UI->new(-color_support => 1,-clear_on_exit => 1);    

    #=======================================================================
    # UI - Main menu
    #=======================================================================
    
    $win{'MM'} = $cui->add(undef, 'Window', -title => 'Archibald: Main menu', %win_args, -onFocus => \&MM_focus);
    
    $win{"MM"}->add('nav', 'Buttonbox', -y => 1, -vertical => 1,
        -buttons  => [
            { -label => 'Configure keymap for the live system', -value => 'ck', -onpress => sub { $win{'CK'}->focus } },
            { -label => 'Configure network for the live system', -value => 'cn', -onpress => sub { $win{'CN'}->focus } },
            { -label => 'Prepare hard drive', -value => 'phd', -onpress => sub { $win{'PHD'}->focus } },
            { -label => 'Select mount points and filesystem *', -value => 'smp', -onpress => sub { $win{'SMP'}->focus } },
            { -label => 'Select installation mirrors', -value => 'sm', -onpress => sub { $win{'SM'}->focus } },
            { -label => 'Install base system *', -value => 'is', -onpress => sub { $win{'IS'}->focus } },
            { -label => 'Configure the new system *', -value => 'cs', -onpress => sub { $win{'CS'}->focus } },
            { -label => 'Configure networking', -value => 'cnet', -onpress => sub { $win{'CNET'}->focus } },
            { -label => 'Show error log', -value => 'l', -onpress => sub { $win{'L'}->focus } },
            { -label => 'Reboot into installed system', -value => 'rs', -onpress => sub { $win{'RS'}->focus } },
            { -label => 'Quit', -value => 'q', -onpress => sub { $win{'Q'}->focus } }
        ]
    );    
    
    #=======================================================================
    # UI - Configure keymap
    #=======================================================================
    
    $win{'CK'} = $cui->add(undef, 'Window', -title => 'Archibald: Configure keymap for the live system', %win_args, -onFocus => \&CK_focus);
    
    $win{'CK'}->add('info', 'Label', -x => 0, -y => 0, -width => -1, -bold => 1);
    
    $win{'CK'}->add('keymaplist', 'Radiobuttonbox', -x => 0, -y => 2, -width => -1, -height => 9, -vscrollbar => 'right', -border => 1, -title => 'Select keymap');
    
    $win{'CK'}->add('nav', 'Buttonbox', -y => -1,
        -buttons  => [
            { -label => '<Apply>', -value => 'apply', -onpress => \&CK_nav_apply },
            { -label => '<Back>', -value => 'back', -onpress => sub { $win{'MM'}->focus } }
        ]
    );            
    
    #=======================================================================
    # UI - Configure network
    #=======================================================================
    
    $win{'CN'} = $cui->add(undef, 'Window', -title => 'Archibald: Configure network for the live system', %win_args, -onFocus => \&CN_focus);
    
    $win{'CN'}->add('info', 'Label', -x => 0, -y => 0, -width => -1, -bold => 1, -text => 'Configure network');
    
    $win{'CN'}->add('interfacelist', 'Radiobuttonbox', -x => 0, -y => 2, -width => -1, -height => 6, -vscrollbar => 'right', -border => 1, -title => 'Available network interfaces');
    
    $win{'CN'}->add('nav', 'Buttonbox', -y => -1,
        -buttons => [
            { -label => '<Enable>', -value => 'enable', -onpress => \&CN_nav_updown },
            { -label => '<Disable>', -value => 'disable', -onpress => \&CN_nav_updown },
            { -label => '<Back>', -value => 'back', -onpress => sub { $win{'MM'}->focus } }
        ]
    );    
 
    #=======================================================================
    # UI - Prepare hard drive
    #=======================================================================
    
    $win{'PHD'} = $cui->add(undef, 'Window', -title => 'Archibald: Prepare hard drive', %win_args, -onFocus => \&PHD_focus);
    
    $win{'PHD'}->add('info', 'Label', -x => 0, -y => 0, -width => -1, -bold => 1, -text => 'CAREFUL: This may erase data on existing partitions');
    
    $win{'PHD'}->add('devicelist', 'Radiobuttonbox', -x => 0, -y => 2, -width => -1, -height => 6, -vscrollbar => 'right', -border => 1, -title => 'Available disks');
    
    $win{'PHD'}->add('nav', 'Buttonbox', -y => -1,
        -buttons => [
            { -label => '<Format with cfdisk>', -value => 'cfdisk', -onpress => \&PHD_nav_format },
            { -label => '<Format with cgdisk (gpt)>', -value => 'cgdisk', -onpress => \&PHD_nav_format },
            { -label => '<Back>', -value => 'back', -onpress => sub { $win{'MM'}->focus } }
        ]
    );    
    
    #=======================================================================
    # UI - Select mount points and filesystem
    #=======================================================================
    
    $win{'SMP'} = $cui->add(undef, 'Window', -title => 'Archibald: Select mount points and filesystem', %win_args, -onFocus => \&SMP_focus);

    $win{'SMP'}->add('info', 'Label', -x => 0, -y => 0, -width => -1, -bold => 1);
        
    $win{'SMP'}->add('devicelist', 'Radiobuttonbox', -x => 0, -y => 2, -width => -1, -height => 5, -vscrollbar => 'right', -border => 1, -title => 'Available disks',
        -onchange => \&SMP_devicelist_change,
        -onFocus => \&SMP_devicelist_focus);
    
    $win{'SMP'}->add('partlist', 'Radiobuttonbox', -x => 0, -y => 7, -width => 25, -height => 5, -border => 1, -vscrollbar => 'right', -title => 'Partitions',
        -onchange => \&SMP_partlist_change,
        -onFocus => \&SMP_partlist_focus);

    $win{'SMP'}->add('mountlist', 'Radiobuttonbox', -x => 25, -y => 7, -width => 25, -height => 5, -border => 1, -vscrollbar => 'right', -title => 'Mount points',
        -onchange => \&SMP_mountlist_change,
        -onFocus => \&SMP_mountlist_focus);
        
    $win{'SMP'}->add('fslist', 'Radiobuttonbox', -x => 50, -y => 7, -width => 25, -height => 5, -border => 1, -vscrollbar => 'right', -title => 'Filesystems',
        -onchange => \&SMP_fslist_change,
        -onFocus => \&SMP_fslist_focus);
    
    $win{'SMP'}->add('parttable', 'Listbox', -x => 0, -y => 12, -width => -1, -height => 5, -border => 1, -vscrollbar => 'right', -focusable => 0, -title => 'Current configuration');
    
    $win{'SMP'}->add('nav', 'Buttonbox', -y => -1, -onFocus => \&SMP_nav_focus,
        -buttons => [
            { -label => '<Add to configuration>', -value => 'add', -onpress => \&SMP_nav_add },
            { -label => '<Apply configuration>', -value => 'apply', -onpress => \&SMP_nav_apply },
            { -label => '<Clear>', -value => 'clear', -onpress => \&SMP_nav_clear },
            { -label => '<Back>', -value => 'back', -onpress => sub { $win{'MM'}->focus } }
        ]
    );    
    
    #=======================================================================
    # UI - Select installation mirror
    #=======================================================================
    
    $win{'SM'} = $cui->add(undef, 'Window', -title => 'Archibald: Select installation mirrors', %win_args, -onFocus => \&SM_focus);
    
    $win{'SM'}->add('info', 'Label', -x => 0, -y => 0, -width => -1, -bold => 1, -title => 'Select the mirrors you want to enable');
    
    $win{'SM'}->add('mirrorlist', 'Listbox', -x => 0, -y => 2, -width => -1, -height => 12, -vscrollbar => 'right', -hscrollbar => 'top', -border => 1, -multi => 1, -title => 'Mirror servers');
    
    $win{'SM'}->add('nav', 'Buttonbox', -y => -1,
        -buttons => [
            { -label => '<Apply selection>', -value => 'apply', -onpress => \&SM_nav_apply },
            { -label => '<Back>', -value => 'back', -onpress => sub { $win{'MM'}->focus } }
        ]
    );    
    
    #=======================================================================
    # UI - Install base system
    #=======================================================================
    
    $win{'IS'} = $cui->add(undef, 'Window', -title => 'Archibald: Install base system', %win_args, -onFocus => \&IS_focus);
    
    $win{'IS'}->add('info', 'Label', -x => 0, -y => 0, -width => -1, -bold => 1, -text => 'Select basic packages');    
    
    $win{'IS'}->add('bootloaderlist', 'Radiobuttonbox', -x => 0, -y => 2, -width => -1, -height => 5, -border => 1, -vscrollbar => 'right', -title => 'Available bootloaders');
    
    $win{'IS'}->add('wirelesstoolscb', 'Checkbox', -x => 1, -y => 8, -label => 'Install wireless tools');
    
    $win{'IS'}->add('nav', 'Buttonbox', -y => -1,
        -buttons => [
            { -label => '<Apply>', -value => 'apply', -onpress => \&IS_nav_apply },
            { -label => '<Back>', -value => 'back', -onpress => sub { $win{'MM'}->focus } }
        ]
    );    
    
    #=======================================================================
    # UI - Configure system
    #=======================================================================
    
    $win{'CS'} = $cui->add(undef, 'Window', -title => 'Archibald: Configure the new system', %win_args, -onFocus => \&CS_focus);
    
    $win{'CS'}->add('info', 'Label', -x => 0, -y => 0, -width => -1, -bold => 1, -text => 'Marked fields are required');    
        
    $win{'CS'}->add('timezonelist', 'Radiobuttonbox', -x => 0, -y => 2, -width => 30, -height => 8, -vscrollbar => 'right', -border => 1, -title => 'Timezone *');    
    $win{'CS'}->add('localelist', 'Listbox', -x => 31, -y => 2, -width => 30, -height => 8, -vscrollbar => 'right', -border => 1, -multi => 1, -title => 'Locales *');
        
    $win{'CS'}->add('localelist_default', 'Radiobuttonbox', -x => 0, -y => 10, -width => 30, -height => 1, -border => 1, -title => 'Language *');    
    $win{'CS'}->add('localetimecb', 'Checkbox', -x => 31, -y => 11, -label => 'Use localtime');
        
    $win{'CS'}->add('rootpassword1', 'PasswordEntry', -x => 0, -y => 13, -width => 30, -border => 1, -title => 'Root password *');
    $win{'CS'}->add('rootpassword2', 'PasswordEntry', -x => 31, -y => 13, -width => 30, -border => 1, -title => 'Repeat root password *');
    
    $win{'CS'}->add('nav', 'Buttonbox', -y => -1,
        -buttons => [
            { -label => '<Apply>', -value => 'apply', -onpress => \&CS_nav_apply },
            { -label => '<Back>', -value => 'back', -onpress => sub { $win{'MM'}->focus } }
        ]
    );    
    
    #=======================================================================
    # UI - Configure networking
    #=======================================================================
    
    $win{'CNET'} = $cui->add(undef, 'Window', -title => 'Archibald: Configure the new system', %win_args, -onFocus => \&CNET_focus);
    
    $win{'CNET'}->add('info', 'Label', -x => 0, -y => 0, -width => -1, -bold => 1, -text => 'Marked fields are required');    
        
    $win{'CNET'}->add('hostnameentry', 'TextEntry', -x => 0, -y => 2, -width => 30, -border => 1, -title => 'Hostname *');
    
    $win{'CNET'}->add('staticipcb', 'Checkbox', -x => 34, -y => 3, -label => 'Use static ip', -checked => 0, -onchange => \&CNET_staticip_changed);    
        
    $win{'CNET'}->add('interfacelist', 'Radiobuttonbox', -x => 0, -y => 5, -width => -1, -height => 6, -vscrollbar => 'right', -border => 1, -title => 'Available network interfaces *');
    
    $win{'CNET'}->add('ipentry', 'TextEntry', -x => 0, -y => 11, -width => 30, -border => 1, -title => 'IP Address');    
    $win{'CNET'}->add('domainentry', 'TextEntry', -x => 31, -y => 11, -width => 30, -border => 1, -title => 'Domain', -text => 'localdomain');
    
    $win{'CNET'}->add('nav', 'Buttonbox', -y => -1,
        -buttons => [
            { -label => '<Apply>', -value => 'apply', -onpress => \&CNET_nav_apply },
            { -label => '<Back>', -value => 'back', -onpress => sub { $win{'MM'}->focus } }
        ]
    );
    
    #=======================================================================
    # UI - Log
    #=======================================================================
    
    $win{'L'} = $cui->add(undef, 'Window', -title => 'Archibald: Showing recent error messages', %win_args, -onFocus => \&L_focus);
    
    $win{'L'}->add('viewer', 'TextViewer', -y => 1, -width => -1, -height => 12, -bold => 1, -singleline => 0, -wrapping => 1, -border => 1, -vscrollbar => 'right');
    
    $win{'L'}->add('nav', 'Buttonbox', -y => -1,
        -buttons => [            
            { -label => '<Back>', -value => 'back', -onpress => sub { $win{'MM'}->focus } }
        ]
    );    
    
    #=======================================================================
    # UI - Reboot system
    #=======================================================================
    
    $win{'RS'} = $cui->add(undef, 'Window', -title => 'Archibald: Reboot system', %win_args, -onFocus => \&RS_focus);
    
    $win{'RS'}->add('info', 'Label', -y => 1, -width => -1, -bold => 1, -text => 'Are you sure?');    
    
    $win{'RS'}->add('nav', 'Buttonbox', -y => -1,
        -buttons => [
            { -label => '<Yes>', -value => 'yes', -onpress => \&RS_nav_yes },
            { -label => '<No>', -value => 'no', -onpress => sub { $win{'MM'}->focus } }
        ]
    );    
    
    #=======================================================================
    # UI - Quit
    #=======================================================================
    
    $win{'Q'} = $cui->add(undef, 'Window', -title => 'Archibald: Quit', %win_args, -onFocus => \&Q_focus);
    
    $win{'Q'}->add('info', 'Label', -y => 1, -width => -1, -bold => 1, -text => 'Are you sure?');    
    
    $win{'Q'}->add('nav', 'Buttonbox', -y => -1,        
        -buttons  => [
            { -label => '<Yes>', -value => 'yes', -onpress => \&handler_quit},
            { -label => '<No>', -value => 'no', -onpress => sub { $win{'MM'}->focus } }
        ]
    );
    
    #=======================================================================
    # Driver
    #=======================================================================
    
    # Bind <CTRL+Q> to quit.
    $cui->set_binding( \&handler_quit, "\cQ" );
    
    $win{'MM'}->focus;
    $cui->mainloop;
}
    
#=======================================================================
1;