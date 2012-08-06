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
            { -label => 'Select mount points and filesystem *', -value => 'smp', -onpress => sub { $win{'SMP'}->focus } },
            { -label => 'Select installation mirrors', -value => 'sm', -onpress => sub { $win{'SM'}->focus } },
            { -label => 'Select packages *', -value => 'sp', -onpress => sub { $win{'SP'}->focus } },
            { -label => 'Configure the new system *', -value => 'cs', -onpress => sub { $win{'CS'}->focus } },
            { -label => 'Configure networking', -value => 'cnet', -onpress => sub { $win{'CNET'}->focus } },
            { -label => 'Install', -value => 'is', -onpress => sub { $win{'IS'}->focus } },
            { -label => 'Show error log', -value => 'l', -onpress => sub { $win{'L'}->focus } },            
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
    # UI - Select mount points and filesystem
    #=======================================================================
    
    $win{'SMP'} = $cui->add(undef, 'Window', -title => 'Archibald: Select mount points and filesystem', %win_args, -onFocus => \&SMP_focus);

    $win{'SMP'}->add('info', 'Label', -x => 0, -y => 0, -width => -1, -bold => 1);
        
    $win{'SMP'}->add('devicelist', 'Radiobuttonbox', -x => 0, -y => 2, -width => 20, -height => 5, -vscrollbar => 'right', -border => 1, -title => 'Available disks',
        -onchange => \&SMP_devicelist_change, -onFocus => \&SMP_devicelist_focus);

    $win{'SMP'}->add('mountlist', 'Radiobuttonbox', -x => 20, -y => 2, -width => 20, -height => 5, -border => 1, -vscrollbar => 'right', -title => 'Mount points',        
        -onchange => \&SMP_mountlist_change, -onFocus => \&SMP_mountlist_focus, -values => ['boot', 'root', 'swap', 'home', 'var', 'dev']);
        
    $win{'SMP'}->add('fslist', 'Radiobuttonbox', -x => 40, -y => 2, -width => 20, -height => 5, -border => 1, -vscrollbar => 'right', -title => 'Filesystems',
        -onchange => \&SMP_fslist_change, -onFocus => \&SMP_fslist_focus, -values => ['ext2', 'ext3', 'ext4', 'swap']);
    
    $win{'SMP'}->add('partsize', 'TextEntry', -x => 60, -y => 2, -width => 20, -border => 1, -title => 'Size (MB)', -onFocus => \&SMP_partsize_focus);
    
    $win{'SMP'}->add('parttable', 'Listbox', -x => 0, -y => 8, -width => -1, -height => 8, -border => 1, -vscrollbar => 'right', -title => 'Current configuration');
    
    $win{'SMP'}->add('nav', 'Buttonbox', -y => -1, -onFocus => \&SMP_nav_focus,
        -buttons => [
            { -label => '<Add to configuration>', -value => 'add', -onpress => \&SMP_nav_add },            
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
    # UI - Select packages
    #=======================================================================
    
    $win{'SP'} = $cui->add(undef, 'Window', -title => 'Archibald: Install base system', %win_args, -onFocus => \&SP_focus);
    
    $win{'SP'}->add('info', 'Label', -x => 0, -y => 0, -width => -1, -bold => 1, -text => 'Select basic packages');    
    
    $win{'SP'}->add('bootloaderlist', 'Radiobuttonbox', -x => 0, -y => 2, -width => -1, -height => 5, -border => 1, -vscrollbar => 'right', -title => 'Available bootloaders');
    
    $win{'SP'}->add('wirelesstoolscb', 'Checkbox', -x => 1, -y => 8, -label => 'Install wireless tools');
    
    $win{'SP'}->add('nav', 'Buttonbox', -y => -1,
        -buttons => [
            { -label => '<Apply>', -value => 'apply', -onpress => \&SP_nav_apply },
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
        
    $win{'CS'}->add('localelist_lang', 'Radiobuttonbox', -x => 0, -y => 10, -width => 30, -height => 1, -border => 1, -title => 'Language *');    
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
    
    $win{'L'}->add('viewer', 'TextViewer', -x => 0, -y => 0, -width => -1, -height => 12, -bold => 1, -singleline => 0, -wrapping => 1, -border => 1, -vscrollbar => 'right');
    
    $win{'L'}->add('nav', 'Buttonbox', -y => -1,
        -buttons => [            
            { -label => '<Back>', -value => 'back', -onpress => sub { $win{'MM'}->focus } }
        ]
    );    
    
    #=======================================================================
    # UI - Make install
    #=======================================================================
    
    $win{'IS'} = $cui->add(undef, 'Window', -title => 'Archibald: Reboot system', %win_args, -onFocus => \&IS_focus);
    
    $win{'IS'}->add('viewer', 'TextViewer', -x => 0, -y => 0, -width => -1, -height => 12, -bold => 1, -singleline => 0, -wrapping => 1, -border => 1, -vscrollbar => 'right');
    
    $win{'IS'}->add('nav', 'Buttonbox', -y => -1,
        -buttons => [
            { -label => '<Generate installation script>', -value => 'ibs', -onpress => \&IS_nav_make_install },            
            { -label => '<Back>', -value => 'back', -onpress => sub { $win{'MM'}->focus } }
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