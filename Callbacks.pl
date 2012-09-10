#!/usr/bin/env perl
#=======================================================================
# Callbacks.pl - Callbacks for the installer generator
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
use File::Basename;
use feature qw(switch);
use Arch;

our %win = ();

our %partitioning_schemes = (
    guided => 'Guided partitioning (Use entire disk)',
    cgdisk => 'Manual partitioning with cgdisk (GPT)'
);

our ( $partitioning_scheme, @available_partitions, @available_mountpoints );

#=======================================================================
# Callbacks - Main menu
#=======================================================================

sub MM_focus {
    my $win    = shift;
    my $viewer = $win->getobj('viewer');
    my $nav    = $win->getobj('nav');

    $viewer->text(
"Welcome to Archibald...\nYou can press CTRL+q to quit without saving at any time.
Fields marked with an asterisk is required for a minimal configuration.
Setting font and fontmap is not advised unless you know it supports your chosen keymap.
Navigate using TAB and SHIFT+TAB, and select items with SPACE.
Press continue to start"
    );

    $nav->focus;
}

#=======================================================================
# Callbacks - Configure keymap
#=======================================================================

sub CK_focus {
    my $win  = shift;
    my $info = $win->getobj('info');
    my ( $keymaplist, $fontlist, $fontmaplist ) = (
        $win->getobj('keymaplist'),
        $win->getobj('fontlist'),
        $win->getobj('fontmaplist')
    );

    my @keymaps = get_keymaps();
    $keymaplist->values( \@keymaps );

    my @fonts = get_fonts();
    $fontlist->values( \@fonts );

    my @fontmaps = get_fontmaps();
    $fontmaplist->values( \@fontmaps );
}

sub CK_nav_continue {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my $info = $win->getobj('info');
    my ( $keymaplist, $fontlist, $fontmaplist ) = (
        $win->getobj('keymaplist'),
        $win->getobj('fontlist'),
        $win->getobj('fontmaplist')
    );

    my $keymap = $keymaplist->get();

    unless ( defined $keymap ) {
        $info->text("You must select a keymap");
        return;
    }

    set_keymap($keymap);
    set_font( $fontlist->get() );
    set_fontmap( $fontmaplist->get() );

    $win{'SPS'}->focus;
}

#=======================================================================
# Callbacks - Select partitioning scheme
#=======================================================================

sub SPS_focus {
    my $win        = shift;
    my $info       = $win->getobj('info');
    my $schemelist = $win->getobj('schemelist');

    $schemelist->values( keys %partitioning_schemes );
    $schemelist->labels(%partitioning_schemes);

    $info->text('Select a partitioning scheme');
}

sub SPS_nav_continue {
    my $bbox       = shift;
    my $win        = $bbox->parent;
    my $info       = $win->getobj('info');
    my $schemelist = $win->getobj('schemelist');

    $partitioning_scheme = $schemelist->get();
    unless ( defined $partitioning_scheme ) {
        $info->text('You must select a partitioning scheme');
        return;
    }

    given ($partitioning_scheme) {
        when ('guided') {
            use_partitioning(1);
            $win{'GP'}->focus;
        }
        when ('cgdisk') {
            use_partitioning(0);
            $win{'SD'}->focus;
        }
    }
}

#=======================================================================
# Callbacks - Guided partitioning
#=======================================================================

sub GP_focus {
    my $win  = shift;
    my $info = $win->getobj('info');
    my ( $devicelist, $parttable ) =
      ( $win->getobj('devicelist'), $win->getobj('parttable') );

    $devicelist->values( get_disks() );
    $parttable->values( [] );
    $devicelist->focus;
    $info->text('Select a disk');
}

sub GP_devicelist_change {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my $info = $win->getobj('info');
    my ( $nav, $parttable, $devicelist ) = (
        $win->getobj('nav'),
        $win->getobj('parttable'),
        $win->getobj('devicelist')
    );

    my $disk = $devicelist->get();
    set_disk($disk);
    my $ret = autogenerate_partition_table($disk);
    if ($ret) {
        $info->text('Disk is too small for guided partitioning');
        return;
    }

    $parttable->values( get_partition_table() );
    $parttable->draw(0);
    $nav->focus;
}

#=======================================================================
# Callbacks - Select disk
#=======================================================================

sub SD_focus {
    my $win        = shift;
    my $info       = $win->getobj('info');
    my $devicelist = $win->getobj('devicelist');

    $devicelist->values( get_disks() );
    $devicelist->focus;
    $info->text('Select a disk...');
}

sub SD_devicelist_change {
    my $bbox       = shift;
    my $win        = $bbox->parent;
    my $devicelist = $win->getobj('devicelist');
    my $viewer     = $win->getobj('viewer');

    my $disk = $devicelist->get();
    set_disk($disk);

    $viewer->text( get_disk_info($disk) );
}

#=======================================================================
# Callbacks - Manual partitioning
#=======================================================================

sub MP_focus {
    my $win  = shift;
    my $cui  = $win->parent;
    my $info = $win->getobj('info');
    my ( $partlist, $mountlist, $fslist ) = (
        $win->getobj('partlist'),
        $win->getobj('mountlist'),
        $win->getobj('fslist')
    );

    $mountlist->clear_selection();
    $fslist->clear_selection();

    $cui->leave_curses();
    system( "clear && $partitioning_scheme " . get_disk() );
    $cui->reset_curses();

    clear_partition_table();
    @available_partitions  = get_partitions( get_disk() );
    @available_mountpoints = get_mountpoints();

    $partlist->values( \@available_partitions );
    $mountlist->values( \@available_mountpoints );
    $fslist->values( 'ext2', 'ext3', 'ext4' );

    $info->text('Select a mountpoint...');
}

sub MP_mountlist_change {
    my $mountlist = shift;
    my $win       = $mountlist->parent;
    my $fslist    = $win->getobj('fslist');

    my $mountpoint = $mountlist->get();
    unless ( defined $mountpoint ) { return }

    given ($mountpoint) {
        when ('bios') {
            $fslist->values('bios');
            $fslist->set_selection(0);
        }
        when ('swap') {
            $fslist->values('swap');
            $fslist->set_selection(0);
        }
        default {
            $fslist->values( 'ext2', 'ext3', 'ext4' );
        }
    }

    $fslist->focus;
}

sub MP_mountlist_focus {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my $info = $win->getobj('info');

    $info->text('Select a mount point...');
}

sub MP_fslist_change {

    #my $bbox = shift;
    #my $win = $bbox->parent;
}

sub MP_fslist_focus {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my $info = $win->getobj('info');

    $info->text('Select a file system type...');
}

sub MP_nav_focus {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my $info = $win->getobj('info');

    $info->text('');
}

sub MP_nav_add {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my $info = $win->getobj('info');
    my ( $partlist, $mountlist, $fslist, $parttable ) = (
        $win->getobj('partlist'), $win->getobj('mountlist'),
        $win->getobj('fslist'),   $win->getobj('parttable')
    );

    my ( $partition, $mountpoint, $filesystem ) =
      ( $partlist->get(), $mountlist->get(), $fslist->get() );

    unless (defined $partition
        and defined $mountpoint
        and defined $filesystem )
    {
        $info->text('You must select partition, mountpoint and filesystem');
        return;
    }

    add_partition_table_entry(
        $partition . ':' . $mountpoint . ':' . $filesystem );

    @available_partitions = grep { $_ ne $partition } @available_partitions;
    $partlist->values( \@available_partitions );

    @available_mountpoints = grep { $_ ne $mountpoint } @available_mountpoints;
    $mountlist->values( \@available_mountpoints );

    $fslist->clear_selection();

    $parttable->values( get_partition_table() );
    $parttable->draw(0);

    $partlist->focus;

    $info->text('Entry added to configuration...');
}

sub MP_nav_clear {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my ( $partlist, $mountlist, $fslist, $parttable ) = (
        $win->getobj('partlist'), $win->getobj('mountlist'),
        $win->getobj('fslist'),   $win->getobj('parttable')
    );

    $mountlist->clear_selection();
    $fslist->clear_selection();

    clear_partition_table();
    @available_partitions  = get_partitions( get_disk() );
    @available_mountpoints = get_mountpoints();

    $partlist->values( \@available_partitions );
    $mountlist->values( \@available_mountpoints );
    $parttable->values( get_partition_table() );
    $parttable->draw(0);
    $partlist->focus;
}

sub MP_nav_continue {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my $info = $win->getobj('info');

    if ( $partitioning_scheme eq 'cgdisk' ) {
        my $bios_partitions = grep { $_ =~ /.+:bios:.+/ } get_partition_table();
        if ( $bios_partitions < 1 ) {
            $info->text(
                'You must configure a bios partition when creating a gpt disk');
            return;
        }
    }

    my $root_partitions = grep { $_ =~ /.+:root:.+/ } get_partition_table();
    if ( $root_partitions < 1 ) {
        $info->text('You must configure a root partition');
        return;
    }

    $win{'SM'}->focus;
}

#=======================================================================
# Callbacks - Select mirror
#=======================================================================

sub SM_focus {
    my $win = shift;
    my ( $info, $mirrorlist ) =
      ( $win->getobj('info'), $win->getobj('mirrorlist') );

    $mirrorlist->values( get_mirrors() );
}

sub SM_nav_continue {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my ( $info, $mirrorlist ) =
      ( $win->getobj('info'), $win->getobj('mirrorlist') );

    my @selected_mirrors = $mirrorlist->get();

    if ( !@selected_mirrors ) {
        $info->text('You must select at least one mirror');
        return;
    }

    set_mirrors(@selected_mirrors);

    $win{'SP'}->focus;
}

#=======================================================================
# Callbacks - Select packages
#=======================================================================

sub SP_focus {
    my $win  = shift;
    my $info = $win->getobj('info');
    my ( $bootloaderlist, $devicelist ) =
      ( $win->getobj('bootloaderlist'), $win->getobj('devicelist') );

    $bootloaderlist->values( ['grub'] );
    $devicelist->values( get_disks() );
}

sub SP_nav_continue {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my $info = $win->getobj('info');
    my ( $bootloaderlist, $devicelist, $wirelesstoolscb ) = (
        $win->getobj('bootloaderlist'),
        $win->getobj('devicelist'),
        $win->getobj('wirelesstoolscb')
    );

    my $bootloader = $bootloaderlist->get();
    set_bootloader($bootloader);

    if ( defined $bootloader ) {
        my $bootloader_disk = $devicelist->get();
        unless ( defined $bootloader_disk ) {
            $info->text("You must select a boot device for $bootloader");
            return;
        }
        set_bootloader_disk( $devicelist->get() );
    }

    install_wirelesstools( $wirelesstoolscb->get() );

    $win{'CS'}->focus;
}

#=======================================================================
# Callbacks - Configure system
#=======================================================================

sub CS_focus {
    my $win          = shift;
    my $info         = $win->getobj('info');
    my $timezonelist = $win->getobj('timezonelist');
    my $localelist   = $win->getobj('localelist');

    # populate timezones
    $timezonelist->values( get_timezones() );

    # populate locale.gen
    $localelist->values( get_locales() );
}

sub CS_localelist_selchange {
    my $localelist      = shift;
    my $win             = $localelist->parent;
    my $localelist_lang = $win->getobj('localelist_lang');
    my $localelist_time = $win->getobj('localelist_time');

    my @trimmed_locales = sort grep { $_ =~ s/\s+.*// } $localelist->get();

    # FIXME
    $localelist_lang->values( \@trimmed_locales );
    $localelist_time->values( \@trimmed_locales );
}

sub CS_nav_continue {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my ( $cui, $info ) = ( $win->parent, $win->getobj('info') );
    my (
        $timezonelist,    $localelist, $localelist_lang,
        $localelist_time, $localtimecb
      )
      = (
        $win->getobj('timezonelist'),    $win->getobj('localelist'),
        $win->getobj('localelist_lang'), $win->getobj('localelist_time'),
        $win->getobj('localtimecb')
      );

    my $timezone = $timezonelist->get();
    unless ( defined $timezone ) {
        $info->text('You must select a timezone');
        return;
    }
    set_timezone($timezone);

    my @locales = $localelist->get();
    if ( !@locales ) {
        $info->text('You must select at least one locale');
        return;
    }
    set_locales(@locales);

    my $locale_lang = $localelist_lang->get();
    unless ( defined $locale_lang ) {
        $info->text('You must select a language');
        return;
    }
    chomp($locale_lang);
    set_locale_lang($locale_lang);

    my $locale_time = $localelist_time->get();
    if ( defined $locale_time ) {
        chomp($locale_time);
        set_locale_time($locale_time);
    }

    use_localtime( $localtimecb->get() );

    $win{'CNET'}->focus;
}

#=======================================================================
# Callbacks - Configure networking
#=======================================================================

sub CNET_focus {
    my $win    = shift;
    my $iflist = $win->getobj('interfacelist');

    $iflist->values( get_network_devices() );
}

sub CNET_interfacelist_changed {
    my $interfacelist = shift;
    my $win           = $interfacelist->parent;
    my $hostnameentry = $win->getobj('hostnameentry');

    my $item = $interfacelist->get();
    if ($item) {
        $hostnameentry->title('Hostname *');
    }
    else {
        $hostnameentry->title('Hostname');
    }
}

sub CNET_staticip_changed {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my ( $interfacelist, $hostnameentry, $ipentry, $domainentry ) = (
        $win->getobj('interfacelist'), $win->getobj('hostnameentry'),
        $win->getobj('ipentry'),       $win->getobj('domainentry')
    );

    my $state = $bbox->get();
    if ($state) {
        $interfacelist->title('Available network interfaces *');
        $hostnameentry->title('Hostname *');
        $ipentry->title('IP Address *');
        $domainentry->title('Domain *');
    }
    else {
        $interfacelist->title('Available network interfaces');
        if ( $interfacelist->get() ) {
            $hostnameentry->title('Hostname *');
        }
        else {
            $hostnameentry->title('Hostname');
        }
        $ipentry->title('IP Address');
        $domainentry->title('Domain');
    }
}

sub CNET_nav_continue {
    my $bbox = shift;
    my $win  = $bbox->parent;
    my $info = $win->getobj('info');
    my (
        $interfacelist, $hostnameentry, $staticipcb, $ipentry,
        $domainentry,   $netmaskentry,  $gatewayentry
      )
      = (
        $win->getobj('interfacelist'), $win->getobj('hostnameentry'),
        $win->getobj('staticipcb'),    $win->getobj('ipentry'),
        $win->getobj('domainentry'),   $win->getobj('netmaskentry'),
        $win->getobj('gatewayentry')
      );

    my $interface = $interfacelist->get();
    if ( defined($interface) ) {
        set_network_device($interface);

        my $hostname = trim( $hostnameentry->get() );
        unless ( length $hostname ) {
            $info->text("You must choose a hostname for interface $interface");
            return;
        }
        set_hostname($hostname);

        my $static_ip = $staticipcb->get();
        if ($static_ip) {
            my $ip = trim( $ipentry->get() );
            unless ( length $ip ) {
                $info->text(
"You must choose a IP address for static interface $interface"
                );
                return;
            }
            set_ip($ip);

            my $domain = trim( $domainentry->get() );
            unless ( length $domain ) {
                $info->text(
                    "You must choose a domain for static interface $interface");
                return;
            }
            set_domain($domain);

            my $netmask = trim( $netmaskentry->get() );
            unless ( length $netmask ) {
                $info->text(
                    "You must choose a netmask for static interface $interface"
                );
                return;
            }
            set_netmask($netmask);

            my $gateway = trim( $gatewayentry->get() );
            unless ( length $gateway ) {
                $info->text(
                    "You must choose a gateway for static interface $interface"
                );
                return;
            }
            set_gateway($gateway);
        }
    }

    $win{'IS'}->focus;
}

#=======================================================================
# Callbacks - Install
#=======================================================================

sub IS_focus {
    my $win = shift;
    my $runinst = $win->getobj('run_installer');

    $runinst->focus;
}

sub IS_nav_make_install {
    my $bbox   = shift;
    my $win    = $bbox->parent;
    my $viewer = $win->getobj('viewer');

    my ( $err, $msg ) = generate_installer();
    if ($err) {
        print STDERR $msg;
        $viewer->text($msg);
    }
    else {
        $viewer->text(
            "Congratulations!
A installer script has been saved as " . get_install_script() . "
You may quit and install Arch linux with the following command: ./"
              . get_install_script()
        );
    }
}

sub IS_quit {
    my $bbox = shift;
	my $win = $bbox->parent;
    my $cui  = $win->parent;
    my $runinst = $win->getobj('run_installer');
	
    $cui->leave_curses();
    $cui->mainloopExit();
    `clear`;
    
    if($runinst->get()) {
        my $install_script = get_install_script();
        `./$install_script`;        
    }    
    exit(0);
}

#=======================================================================
1
__END__
