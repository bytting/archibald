#!/usr/bin/env perl
#=======================================================================
# Arch_UI.pl - UI for archibald
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
use Curses::UI;

require "./Callbacks.pl";

my $cui;
my %win_args = (
    -border       => 1,
    -titlereverse => 0,
    -pad          => 1,
    -ipad         => 1,
    -bfg          => 'red',
    -tfg          => 'green'
);
my %info_args = ( -x => 0, -y => 0, -width => -1, -bold => 1, -fg => 'yellow' );

sub handler_quit() {
    $cui->mainloopExit() if defined($cui);
    exit(0);
}

sub run() {
    use vars qw(%win %p);

    $cui = Curses::UI->new( -color_support => 1, -clear_on_exit => 1 );

    #=======================================================================
    # UI - Main menu
    #=======================================================================

    $win{'MM'} = $cui->add(
        undef, 'Window',
        -title => 'Archibald: Main menu',
        %win_args, -onFocus => \&MM_focus
    );

    $win{'MM'}->add(
        'viewer', 'TextViewer',
        -x          => 0,
        -y          => 0,
        -width      => -1,
        -height     => 16,
        -bold       => 1,
        -singleline => 0,
        -wrapping   => 1,
        -vscrollbar => 'right'
    );

    $win{"MM"}->add(
        'nav',
        'Buttonbox',
        -y       => -1,
        -buttons => [
            {
                -label   => '<Quit>',
                -value   => 'quit',
                -onpress => \&handler_quit
            },
            {
                -label   => '<Continue>',
                -value   => 'continue',
                -onpress => sub { $win{'CK'}->focus }
            }
        ]
    );

    #=======================================================================
    # UI - Configure keymap
    #=======================================================================

    $win{'CK'} = $cui->add(
        undef, 'Window',
        -title => 'Archibald: Select keymap',
        %win_args, -onFocus => \&CK_focus
    );

    $win{'CK'}->add( 'info', 'Label', %info_args,
        -text => 'Select keymap, font and fontmap' );

    $win{'CK'}->add(
        'keymaplist', 'Radiobuttonbox',
        -x          => 0,
        -y          => 2,
        -width      => 38,
        -height     => 14,
        -vscrollbar => 'right',
        -border     => 1,
        -title      => 'Available keymaps *'
    );

    $win{'CK'}->add(
        'fontlist', 'Radiobuttonbox',
        -x          => 38,
        -y          => 2,
        -width      => 34,
        -height     => 7,
        -vscrollbar => 'right',
        -border     => 1,
        -title      => 'Available fonts'
    );

    $win{'CK'}->add(
        'fontmaplist', 'Radiobuttonbox',
        -x          => 38,
        -y          => 9,
        -width      => 34,
        -height     => 7,
        -vscrollbar => 'right',
        -border     => 1,
        -title      => 'Available fontmaps'
    );

    $win{'CK'}->add(
        'nav',
        'Buttonbox',
        -y       => -1,
        -buttons => [
            {
                -label   => '<Back>',
                -value   => 'back',
                -onpress => sub { $win{'MM'}->focus }
            },
            {
                -label   => '<Continue>',
                -value   => 'continue',
                -onpress => \&CK_nav_continue
            }
        ]
    );

    #=======================================================================
    # UI - Select partitioning scheme
    #=======================================================================

    $win{'SPS'} = $cui->add(
        undef, 'Window',
        -title => 'Archibald: Select partitioning scheme',
        %win_args, -onFocus => \&SPS_focus
    );

    $win{'SPS'}->add( 'info', 'Label', %info_args );

    $win{'SPS'}->add(
        'schemelist', 'Radiobuttonbox',
        -x          => 0,
        -y          => 2,
        -width      => -1,
        -height     => 12,
        -vscrollbar => 'right',
        -border     => 1,
        -title      => 'Partitionong schemes'
    );

    $win{'SPS'}->add(
        'nav',
        'Buttonbox',
        -y       => -1,
        -buttons => [
            {
                -label   => '<Back>',
                -value   => 'back',
                -onpress => sub { $win{'CK'}->focus }
            },
            {
                -label   => '<Continue>',
                -value   => 'continue',
                -onpress => \&SPS_nav_continue
            }
        ]
    );

    #=======================================================================
    # UI - Guided partitioning
    #=======================================================================

    $win{'GP'} = $cui->add(
        undef, 'Window',
        -title => 'Archibald: Guided partitioning',
        %win_args, -onFocus => \&GP_focus
    );

    $win{'GP'}->add( 'info', 'Label', %info_args );

    $win{'GP'}->add(
        'devicelist', 'Radiobuttonbox',
        -x          => 0,
        -y          => 2,
        -width      => -1,
        -height     => 6,
        -vscrollbar => 'right',
        -border     => 1,
        -title      => 'Available disks',
        -onchange   => \&GP_devicelist_change
    );

    $win{'GP'}->add(
        'parttable', 'Listbox',
        -x          => 0,
        -y          => 8,
        -width      => -1,
        -height     => 8,
        -border     => 1,
        -vscrollbar => 'right',
        -title      => 'Partition | Mountpoint | Filesystem | Size (MB)'
    );

    $win{'GP'}->add(
        'nav',
        'Buttonbox',
        -y       => -1,
        -buttons => [
            {
                -label   => '<Back>',
                -value   => 'back',
                -onpress => sub { $win{'SPS'}->focus }
            },
            {
                -label   => '<Continue>',
                -value   => 'continue',
                -onpress => sub { $win{'SM'}->focus }
            }
        ]
    );

    #=======================================================================
    # UI - Select disk
    #=======================================================================

    $win{'SD'} = $cui->add(
        undef, 'Window',
        -title => 'Archibald: Select disk',
        %win_args, -onFocus => \&SD_focus
    );

    $win{'SD'}->add( 'info', 'Label', %info_args );

    $win{'SD'}->add(
        'devicelist', 'Radiobuttonbox',
        -x          => 0,
        -y          => 2,
        -width      => -1,
        -height     => 6,
        -vscrollbar => 'right',
        -border     => 1,
        -title      => 'Available disks',
        -onchange   => \&SD_devicelist_change
    );

    $win{'SD'}->add(
        'viewer', 'TextViewer',
        -x          => 0,
        -y          => 8,
        -width      => -1,
        -height     => 9,
        -bold       => 1,
        -singleline => 0,
        -border     => 1,
        -title      => 'Current disk layout',
        -wrapping   => 1,
        -vscrollbar => 'right'
    );

    $win{'SD'}->add(
        'nav',
        'Buttonbox',
        -y       => -1,
        -buttons => [
            {
                -label   => '<Back>',
                -value   => 'back',
                -onpress => sub { $win{'SPS'}->focus }
            },
            {
                -label   => '<Continue>',
                -value   => 'continue',
                -onpress => sub { $win{'MP'}->focus }
            }
        ]
    );

    #=======================================================================
    # UI - Manual partitioning
    #=======================================================================

    $win{'MP'} = $cui->add(
        undef, 'Window',
        -title => 'Archibald: Select mountpoints and filesystems',
        %win_args, -onFocus => \&MP_focus
    );

    $win{'MP'}->add( 'info', 'Label', %info_args );

    $win{'MP'}->add(
        'partlist', 'Radiobuttonbox',
        -x          => 0,
        -y          => 2,
        -width      => 25,
        -height     => 6,
        -border     => 1,
        -vscrollbar => 'right',
        -title      => 'Partitions'
    );

    $win{'MP'}->add(
        'mountlist', 'Radiobuttonbox',
        -x          => 25,
        -y          => 2,
        -width      => 25,
        -height     => 6,
        -border     => 1,
        -vscrollbar => 'right',
        -title      => 'Mountpoints',
        -onchange   => \&MP_mountlist_change,
        -onFocus    => \&MP_mountlist_focus
    );

    $win{'MP'}->add(
        'fslist', 'Radiobuttonbox',
        -x          => 50,
        -y          => 2,
        -width      => 25,
        -height     => 6,
        -border     => 1,
        -vscrollbar => 'right',
        -title      => 'Filesystems',
        -onchange   => \&MP_fslist_change,
        -onFocus    => \&MP_fslist_focus
    );

    $win{'MP'}->add(
        'parttable', 'Listbox',
        -x          => 0,
        -y          => 8,
        -width      => -1,
        -height     => 8,
        -border     => 1,
        -vscrollbar => 'right',
        -title      => 'Current configuration'
    );

    $win{'MP'}->add(
        'opt',
        'Buttonbox',
        -y       => -3,
        -onFocus => \&MP_nav_focus,
        -buttons => [
            {
                -label   => '<Add to configuration>',
                -value   => 'add',
                -onpress => \&MP_nav_add
            },
            {
                -label   => '<Clear>',
                -value   => 'clear',
                -onpress => \&MP_nav_clear
            }
        ]
    );

    $win{'MP'}->add(
        'nav',
        'Buttonbox',
        -y       => -1,
        -onFocus => \&MP_nav_focus,
        -buttons => [
            {
                -label   => '<Back>',
                -value   => 'back',
                -onpress => sub { $win{'SD'}->focus }
            },
            {
                -label   => '<Continue>',
                -value   => 'continue',
                -onpress => \&MP_nav_continue
            }
        ]
    );

    #=======================================================================
    # UI - Select installation mirror
    #=======================================================================

    $win{'SM'} = $cui->add(
        undef, 'Window',
        -title => 'Archibald: Select installation mirrors',
        %win_args, -onFocus => \&SM_focus
    );

    $win{'SM'}->add( 'info', 'Label', %info_args,
        -text => 'Select the mirrors you want to enable' );

    $win{'SM'}->add(
        'mirrorlist', 'Listbox',
        -x          => 0,
        -y          => 2,
        -width      => -1,
        -height     => 14,
        -vscrollbar => 'right',
        -hscrollbar => 'top',
        -border     => 1,
        -multi      => 1,
        -title      => 'Mirror servers'
    );

    $win{'SM'}->add(
        'nav',
        'Buttonbox',
        -y       => -1,
        -buttons => [
            {
                -label   => '<Back>',
                -value   => 'back',
                -onpress => sub { $win{'GP'}->focus }
            },
            {
                -label   => '<Continue>',
                -value   => 'continue',
                -onpress => \&SM_nav_continue
            }
        ]
    );

    #=======================================================================
    # UI - Select packages
    #=======================================================================

    $win{'SP'} = $cui->add(
        undef, 'Window',
        -title => 'Archibald: Install base system',
        %win_args, -onFocus => \&SP_focus
    );

    $win{'SP'}
      ->add( 'info', 'Label', %info_args, -text => 'Select basic packages' );

    $win{'SP'}->add(
        'bootloaderlist', 'Radiobuttonbox',
        -x          => 0,
        -y          => 2,
        -width      => -1,
        -height     => 5,
        -border     => 1,
        -vscrollbar => 'right',
        -title      => 'Available bootloaders'
    );

    $win{'SP'}->add(
        'devicelist', 'Radiobuttonbox',
        -x          => 0,
        -y          => 7,
        -width      => -1,
        -height     => 6,
        -vscrollbar => 'right',
        -border     => 1,
        -title      => 'Install bootloader on'
    );

    $win{'SP'}->add(
        'wirelesstoolscb', 'Checkbox',
        -x     => 1,
        -y     => 13,
        -label => 'Install wireless tools'
    );

    $win{'SP'}->add(
        'nav',
        'Buttonbox',
        -y       => -1,
        -buttons => [
            {
                -label   => '<Back>',
                -value   => 'back',
                -onpress => sub { $win{'SM'}->focus }
            },
            {
                -label   => '<Continue>',
                -value   => 'continue',
                -onpress => \&SP_nav_continue
            }
        ]
    );

    #=======================================================================
    # UI - Configure system
    #=======================================================================

    $win{'CS'} = $cui->add(
        undef, 'Window',
        -title => 'Archibald: Configure the new system',
        %win_args, -onFocus => \&CS_focus
    );

    $win{'CS'}->add( 'info', 'Label', %info_args,
        -text => 'Marked fields are required' );

    $win{'CS'}->add(
        'timezonelist', 'Radiobuttonbox',
        -x          => 0,
        -y          => 2,
        -width      => 35,
        -height     => 7,
        -vscrollbar => 'right',
        -border     => 1,
        -title      => 'Timezone *'
    );
    $win{'CS'}->add(
        'localelist', 'Listbox',
        -x          => 35,
        -y          => 2,
        -width      => 35,
        -height     => 7,
        -vscrollbar => 'right',
        -border     => 1,
        -multi      => 1,
        -title      => 'Locales *',
        -onchange   => \&CS_localelist_selchange
    );

    $win{'CS'}->add(
        'localelist_lang', 'Radiobuttonbox',
        -x      => 0,
        -y      => 9,
        -width  => 35,
        -height => 6,
        -border => 1,
        -title  => 'LANG *'
    );
    $win{'CS'}->add(
        'localelist_time', 'Radiobuttonbox',
        -x      => 35,
        -y      => 9,
        -width  => 35,
        -height => 6,
        -border => 1,
        -title  => 'LC_TIME'
    );

    $win{'CS'}->add(
        'localtimecb', 'Checkbox',
        -x     => 35,
        -y     => 15,
        -label => 'Use localtime'
    );

    $win{'CS'}->add(
        'nav',
        'Buttonbox',
        -y       => -1,
        -buttons => [
            {
                -label   => '<Back>',
                -value   => 'back',
                -onpress => sub { $win{'SP'}->focus }
            },
            {
                -label   => '<Continue>',
                -value   => 'continue',
                -onpress => \&CS_nav_continue
            }
        ]
    );

    #=======================================================================
    # UI - Configure networking
    #=======================================================================

    $win{'CNET'} = $cui->add(
        undef, 'Window',
        -title => 'Archibald: Configure networking',
        %win_args, -onFocus => \&CNET_focus
    );

    $win{'CNET'}->add( 'info', 'Label', %info_args,
        -text => 'Marked fields are required' );

    $win{'CNET'}->add(
        'interfacelist', 'Radiobuttonbox',
        -x           => 0,
        -y           => 2,
        -width       => 61,
        -height      => 6,
        -vscrollbar  => 'right',
        -border      => 1,
        -title       => 'Available network interfaces',
        -onselchange => \&CNET_interfacelist_changed
    );

    $win{'CNET'}->add(
        'hostnameentry', 'TextEntry',
        -x      => 0,
        -y      => 8,
        -width  => 30,
        -border => 1,
        -title  => 'Hostname'
    );

    $win{'CNET'}->add(
        'staticipcb', 'Checkbox',
        -x        => 34,
        -y        => 9,
        -label    => 'Use static ip',
        -checked  => 0,
        -onchange => \&CNET_staticip_changed
    );

    $win{'CNET'}->add(
        'ipentry', 'TextEntry',
        -x      => 0,
        -y      => 11,
        -width  => 30,
        -border => 1,
        -title  => 'IP Address'
    );
    $win{'CNET'}->add(
        'domainentry', 'TextEntry',
        -x      => 31,
        -y      => 11,
        -width  => 30,
        -border => 1,
        -title  => 'Domain',
        -text   => 'localdomain'
    );

    $win{'CNET'}->add(
        'netmaskentry', 'TextEntry',
        -x      => 0,
        -y      => 14,
        -width  => 30,
        -border => 1,
        -title  => 'Netmask',
        -text   => '255.255.255.0'
    );
    $win{'CNET'}->add(
        'gatewayentry', 'TextEntry',
        -x      => 31,
        -y      => 14,
        -width  => 30,
        -border => 1,
        -title  => 'Gateway',
        -text   => '192.168.1.1'
    );

    $win{'CNET'}->add(
        'nav',
        'Buttonbox',
        -y       => -1,
        -buttons => [
            {
                -label   => '<Back>',
                -value   => 'back',
                -onpress => sub { $win{'CS'}->focus }
            },
            {
                -label   => '<Continue>',
                -value   => 'continue',
                -onpress => \&CNET_nav_continue
            }
        ]
    );

    #=======================================================================
    # UI - Make install
    #=======================================================================

    $win{'IS'} = $cui->add(
        undef, 'Window',
        -title => 'Archibald: Installation',
        %win_args, -onFocus => \&IS_focus
    );

    $win{'IS'}->add(
        'viewer', 'TextViewer',
        -x          => 0,
        -y          => 0,
        -width      => -1,
        -height     => 10,
        -bold       => 1,
        -singleline => 0,
        -wrapping   => 1,
        -vscrollbar => 'right'
    );

	$win{'IS'}->add('run_installer', 'Checkbox', -x => 0, -y => -4, -label => 'Run installer when quitting', -checked => 1);

    $win{'IS'}->add(
        'opt',
        'Buttonbox',
        -y       => -2,
        -buttons => [
            {
                -label   => '<Generate installation script>',
                -value   => 'gis',
                -onpress => \&IS_nav_make_install
            }
        ]
    );

    $win{'IS'}->add(
        'nav',
        'Buttonbox',
        -y       => -1,
        -buttons => [
            {
                -label   => '<Back>',
                -value   => 'back',
                -onpress => sub { $win{'CNET'}->focus }
            },
            {
                -label   => '<Quit>',
                -value   => 'continue',
                -onpress => \&IS_quit
            }

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
1
__END__
