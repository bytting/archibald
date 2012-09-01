#=======================================================================
# Arch.pm - Perl module for generating a Archlinux installer
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

package Arch v0.0.1;

# Exported symbols

our @EXPORT = qw(
  trim
  get_keymaps
  get_fonts
  get_fontmaps
  set_keymap
  set_font
  set_fontmap
  get_disks
  get_disk_size
  get_disk_model
  get_partitions
  get_partition_size
  get_partition_table
  clear_partition_table
  add_partition_table_entry
  autogenerate_partition_table
  set_disk
  get_disk
  get_disk_info
  get_mountpoints
  get_mirrors
  set_mirrors
  install_wirelesstools
  set_bootloader
  set_bootloader_disk
  get_timezones
  get_locales
  set_timezone
  set_locales
  set_locale_lang
  set_locale_time
  use_localtime
  get_network_devices
  set_network_device
  set_hostname
  set_ip
  set_domain
  set_netmask
  set_gateway
  use_partitioning
  get_install_script
  generate_installer
);

# our @EXPORT_OK = qw();

use parent qw(Exporter);
use warnings;
use strict;
use feature qw{switch};
use File::Find;

use constant MEGA => 1024 * 1024;

# Module variables

my (
    $keymap,             $keymap_directory,  $keymap_extension,
    $font,               $font_directory,    $font_extension,
    $fontmap,            $fontmap_directory, $fontmap_extension,
    $bootloader,         $bootloader_disk,   $wirelesstools,
    @partition_table,    $mirrorlist,        @mirrors,
    $timezone_directory, $locale_gen,        $rc_conf,
    $timezone,           $use_localtime,     @locales,
    $locale_lang,        $locale_time,       $hostname,
    $interface,          $static_ip,         $ip,
    $domain,             $netmask,           $gateway,
    %disks,              %partitions,        $disk,
    @mountpoints,        $install_script,    $use_partitioning,
	%net_devices
);

# Default values

$keymap             = 'us';
$keymap_directory   = '/usr/share/kbd/keymaps/';
$keymap_extension   = '.map.gz';
$font               = '';
$font_directory     = '/usr/share/kbd/consolefonts/';
$font_extension     = '.gz';
$fontmap            = '';
$fontmap_directory  = '/usr/share/kbd/consoletrans/';
$fontmap_extension  = '.trans';
$bootloader         = 'grub';
$wirelesstools      = 0;
$mirrorlist         = '/etc/pacman.d/mirrorlist';
$timezone_directory = '/usr/share/zoneinfo/';
$locale_gen         = '/etc/locale.gen';
$rc_conf            = '/etc/rc.conf';
$use_localtime      = 0;
$install_script     = 'arch-install';

#=======================================================================
# trim: Trim whitespace off a string
#=======================================================================

sub trim($) {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

#=======================================================================
# find_files_deep: Get a list of files recursively
#=======================================================================

sub find_files_deep {
    my $dir = shift;
    my $ext = shift;
    return ( 1, () ) unless -d $dir;

    my @files;
    my $map_finder = sub {
        return unless -f;
        return unless /$ext$/;
        push @files, $File::Find::name;
    };
    find( $map_finder, $dir );
    return ( 0, sort @files );
}

#=======================================================================
# emit: Emit text to a file handle
#=======================================================================

sub emit {
    my ( $handle, $cmd ) = @_;
    print $handle $cmd;
}

#=======================================================================
# emit_line: Emit text to a file handle with newline
#=======================================================================

sub emit_line {
    my ( $handle, $cmd ) = @_;
    emit( $handle, "$cmd\n" );
}

#=======================================================================
# get_keymaps: return all keymaps on system
#=======================================================================

sub get_keymaps {
    my ( $err, @keymaps ) =
      find_files_deep( $keymap_directory, $keymap_extension );
    return () if ($err);

    foreach (@keymaps) {
        s/^$keymap_directory//;
        s/$keymap_extension$//;
    }
    return sort @keymaps;
}

#=======================================================================
# get_fonts: return all fonts found on system
#=======================================================================

sub get_fonts {
    my ( $err, @fonts ) = find_files_deep( $font_directory, $font_extension );
    return () if ($err);

    foreach (@fonts) {
        s/^$font_directory//;
        s/$font_extension$//;
        s/\.psf[u]*$//;
        s/\.fnt$//;
    }
    return sort @fonts;
}

#=======================================================================
# get_fontmaps: return all fontmaps found on system
#=======================================================================

sub get_fontmaps {
    my ( $err, @fontmaps ) =
      find_files_deep( $fontmap_directory, $fontmap_extension );
    return () if ($err);

    foreach (@fontmaps) {
        s/^$fontmap_directory//;
        s/$fontmap_extension$//;
        s/_to_.*$//;
    }
    return sort @fontmaps;
}

#=======================================================================
# set_keymap: Save and set keymap
#=======================================================================

sub set_keymap {
    my $km = shift;
    $keymap = ( split( /\//, $km ) )[-1];
    `loadkeys $keymap`;
}

#=======================================================================
# set_font: Save font
#=======================================================================

sub set_font {
    $font = shift;
}

#=======================================================================
# set_fontmap: Save fontmap
#=======================================================================

sub set_fontmap {
    $fontmap = shift;
}

#=======================================================================
# load_devices: Load all disks and partitions on system
#=======================================================================

sub load_devices {
    foreach (`lsblk -b -l -n -r -o NAME,SIZE,TYPE`) {
        my @items = split;
        given ( $items[2] ) {
            when ('disk') {
                $disks{ '/dev/' . $items[0] }{size} = int( $items[1] );
            }
            when ('part') {
                $partitions{ '/dev/' . $items[0] }{size} = int( $items[1] );
            }
        }
    }
}

#=======================================================================
# get_disks: return all disks
#=======================================================================

sub get_disks {
    load_devices();
    return sort keys %disks;
}

#=======================================================================
# get_disk_size: return the size of a disk
#=======================================================================

sub get_disk_size {
    my $disk = shift;
    load_devices();
    return $disks{$disk}{size};
}

#=======================================================================
# get_disk_model: return the model of a disk
#=======================================================================

sub get_disk_model {
    my $dsk = shift;
    return `lsblk -n -d -o MODEL $dsk`;
}

#=======================================================================
# get_partitions: get partitions for one/all disks
#=======================================================================

sub get_partitions {
    my $disk = shift;
    load_devices();
    return sort keys %partitions unless defined($disk);
    return sort grep( /^$disk/, keys %partitions );
}

#=======================================================================
# get_partition_size: return the size of a partition
#=======================================================================

sub get_partition_size {
    my $part = shift;
    load_devices();
    return $partitions{$part}{size};
}

#=======================================================================
# get_partition_table: return the configuration partition table
#=======================================================================

sub get_partition_table {
    return @partition_table;
}

#=======================================================================
# clear_partition_table: clear the configuration partition table
#=======================================================================

sub clear_partition_table {
    @partition_table = ();
}

#=======================================================================
# add_partition_table_entry: add a new entry to the configuration partition table
#=======================================================================

sub add_partition_table_entry {
    my $entry = shift;
    push @partition_table, $entry;
}

#=======================================================================
# autogenerate_partition_table: generate a partition table for a speciffic disk
#=======================================================================

sub autogenerate_partition_table {
    my $dsk = shift;

    my $size = get_disk_size($dsk) / MEGA;
    return 1 if ( $size < 7250 );

    my $rest   = int($size) - 2 - 200 - 2048;
    my $partnr = 1;
    my $bios   = "$dsk" . $partnr++ . ":bios:bios:2";
    my $boot   = "$dsk" . $partnr++ . ":boot:ext2:200";
    my $swap   = "$dsk" . $partnr++ . ":swap:swap:2048";
    my $root   = "$dsk" . $partnr++ . ":root:ext4:$rest";

    @partition_table = ( $bios, $boot, $swap, $root );
    return 0;
}

#=======================================================================
# set_disk: Save the configuration disk
#=======================================================================

sub set_disk {
    $disk = shift;
}

#=======================================================================
# get_disk: return the configuration disk
#=======================================================================

sub get_disk {
    return $disk;
}

#=======================================================================
# get_disk_info: return information about a disk
#=======================================================================

sub get_disk_info {
    my $dsk = shift;
    return join( "", `lsblk -o NAME,SIZE,TYPE,ALIGNMENT,FSTYPE $dsk` );
}

#=======================================================================
# get_mountpoints: return all pre-defined mountpoints
#=======================================================================

sub get_mountpoints {
    return ( 'bios', 'boot', 'swap', 'root', 'home', 'usr', 'var', 'dev',
        'sys' );
}

#=======================================================================
# get_mirrors: return all repository mirrors
#=======================================================================

sub get_mirrors {
    unless ( -e $mirrorlist ) {
        print STDERR "The file $mirrorlist was not found";
        return;
    }

    open FILE, $mirrorlist;
    my @content = <FILE>;
    close FILE;
    my ( $url, $prev, %mirrors );
    foreach (@content) {
        if (/^\s*#*\s*Server\s*=\s*(.*)/) {
            $url = $1;
            $prev =~ s/^[\s#]*//;
            $mirrors{$url} = $prev;
        }
        $prev = $_;
    }
    return map { "$mirrors{$_} - $_" } keys %mirrors;
}

#=======================================================================
# set_mirrors: Save configuration mirrors
#=======================================================================

sub set_mirrors {
    @mirrors = @_;
}

#=======================================================================
# install_wirelesstools: Enable/disable wirelesstools
#=======================================================================

sub install_wirelesstools {
    $wirelesstools = shift;
}

#=======================================================================
# set_bootloader: Save configuration bootloader
#=======================================================================

sub set_bootloader {
    $bootloader = shift;
}

#=======================================================================
# set_bootloader_disk: Save installation disk for the bootloader
#=======================================================================

sub set_bootloader_disk {
    $bootloader_disk = shift;
}

#=======================================================================
# get_timezones: return all timezones found on system
#=======================================================================

sub get_timezones {
    my @zones;
    my $map_finder = sub {
        return unless /^[A-Z]/;
        push @zones, $File::Find::name;
    };

    find( $map_finder, $timezone_directory );

    foreach (@zones) {
        s/^$timezone_directory//;
    }
    return sort @zones;
}

#=======================================================================
# get_locales: return all locales found on system
#=======================================================================

sub get_locales {
    unless ( -e $locale_gen ) {
        print STDERR "The file $locale_gen was not found";
        return;
    }

    open FILE, $locale_gen;
    my @content = <FILE>;
    close FILE;
    my @locales;
    foreach (@content) {
        if (/^#*[a-z]{2,3}_/) {
            s/^#*//;
            push @locales, $_;
        }
    }
    return @locales;
}

#=======================================================================
# set_timezone: Save configuration timezone
#=======================================================================

sub set_timezone {
    $timezone = shift;
}

#=======================================================================
# set_locales: Save configuration locales
#=======================================================================

sub set_locales {
    @locales = @_;
}

#=======================================================================
# set_locale_lang: Save language locale
#=======================================================================

sub set_locale_lang {
    $locale_lang = shift;
}

#=======================================================================
# set_locale_time: Save time locale
#=======================================================================

sub set_locale_time {
    $locale_time = shift;
}

#=======================================================================
# use_localtime: Enable/disable localtime (vs UTC)
#=======================================================================

sub use_localtime {
    $use_localtime = shift;
}

#=======================================================================
# load_network_devices: load all network devices
#=======================================================================

sub load_network_devices {
	for(`ip link`) {
		if(/^\d+:\s*(\w+):.*state\s+(\w+)/) {
			next if ($1 eq 'lo');
			$net_devices{$1}{state} = $2;
			$net_devices{$1}{has_interface} = 0;
		}
	}
	
	for my $dev (keys %net_devices) {
		my $info = `iwconfig $dev 2>&1`;
		if($info =~ /.+no wireless extensions.+/) {
			$net_devices{$dev}{type} = 'wired';
		}
		else {
			$net_devices{$dev}{type} = 'wireless';
		}
	}
	
	for(`ip addr`) {
		if(/^\d+:\s*(\w+):/) {
			next if ($1 eq 'lo');
			$net_devices{$1}{has_interface} = 1;
		}		
	}
}

#=======================================================================
# get_network_devices: return all network devices found on system
#=======================================================================

sub get_network_devices {
	load_network_devices();
    return keys %net_devices;
}

#=======================================================================
# get_network_interfaces: return all network interfaces
#=======================================================================

sub get_network_interfaces {
	load_network_devices();
	return grep { $net_devices{$_}{has_interface} } keys %net_devices;
}

#=======================================================================
# set_interface: Save configuration network interface
#=======================================================================

sub set_network_device {
    $interface = shift;
}

#=======================================================================
# set_hostname: Save configuration hostname
#=======================================================================

sub set_hostname {
    $hostname = shift;
}

#=======================================================================
# set_ip: Save configuration ip address
#=======================================================================

sub set_ip {
    $ip = shift;
}

#=======================================================================
# set_domain: Save configuration domain name
#=======================================================================

sub set_domain {
    $domain = shift;
}

#=======================================================================
# set_netmask: Save configuration network mask
#=======================================================================

sub set_netmask {
    $netmask = shift;
}

#=======================================================================
# set_gateway: Save configuration network gateway
#=======================================================================

sub set_gateway {
    $gateway = shift;
}

#=======================================================================
# use_partitioning: Enable/disable partitioning (disable this if user did manual partitioning)
#=======================================================================

sub use_partitioning {
    $use_partitioning = shift;
}

#=======================================================================
# get_install_script: return the filename of the install script
#=======================================================================

sub get_install_script {
    return $install_script;
}

#=======================================================================
# generate_installer: Generate installer script based on collected configuration
#=======================================================================

sub generate_installer {
    my $install_disk = $disk;

    # make sure all required variables are set

    unless ( defined $install_disk ) {
        return ( 1, 'Installation disk undefined' );
    }

    # create and generate the installer script

    open my $inst, ">$install_script";
    emit_line( $inst, "#!/bin/bash" );
    emit_line( $inst, "set -e" );
    emit_line( $inst,
        "if [[ \$1 != \"--configure\" ]]; then # This part runs before chroot"
    );

    if ($use_partitioning) {
        emit_line( $inst, "parted -s $install_disk mktable gpt" );

        my $last_mountpoint;
        foreach (@partition_table) {
            my ( $partition, $mountpoint, $filesystem, $size ) = split /:/;
            if ( defined($last_mountpoint) ) {
                emit_line( $inst,
                    "$mountpoint=\$((\$$last_mountpoint + $size))" );
                emit_line( $inst,
"parted $install_disk unit MiB mkpart primary \$$last_mountpoint \$$mountpoint"
                );
            }
            else {
                emit_line( $inst, "$mountpoint=\$((1 + $size))" );
                emit_line( $inst,
"parted $install_disk unit MiB mkpart primary 1 \$$mountpoint"
                );
            }
            $last_mountpoint = $mountpoint;
        }
    }

    emit( $inst, "\n" );

    my $separate_boot_partition = grep { $_ =~ /.+:boot:.+/ } @partition_table;

    foreach (@partition_table) {
        my ( $partition, $mountpoint, $filesystem, $size ) = split /:/;
        given ($filesystem) {
            when ('ext2') {
                emit_line( $inst, "mkfs.ext2 $partition" );
            }
            when ('ext3') {
                emit_line( $inst, "mkfs.ext3 $partition" );
            }
            when ('ext4') {
                emit_line( $inst, "mkfs.ext4 $partition" );
            }
            when ('swap') {
                emit_line( $inst, "mkswap $partition" );
                emit_line( $inst, "swapon $partition" );
            }
        }

        if ( $mountpoint eq 'root' ) {
            if ( !$separate_boot_partition ) {
                $partition =~ /.+(\d)$/;
                emit_line( $inst, "parted $install_disk set $1 boot on" );
            }
            emit_line( $inst, "mount $partition /mnt" );
        }
    }

    emit( $inst, "\n" );

    foreach (@partition_table) {
        my ( $partition, $mountpoint, $filesystem, $size ) = split /:/;
        $partition =~ /.+(\d)$/;
        my $partition_number = $1;
        given ($mountpoint) {
            when ('bios') {
                emit_line( $inst,
                    "parted $install_disk set $partition_number bios_grub on" );
            }
            when ('boot') {
                emit_line( $inst,
                    "parted $install_disk set $partition_number boot on" );
                emit_line( $inst, "mkdir /mnt/boot" );
                emit_line( $inst, "mount $partition /mnt/boot" );
            }
            when ('home') {
                emit_line( $inst, "mkdir /mnt/home" );
                emit_line( $inst, "mount $partition /mnt/home" );
            }
            when ('usr') {
                emit_line( $inst, "mkdir /mnt/usr" );
                emit_line( $inst, "mount $partition /mnt/usr" );
            }
            when ('var') {
                emit_line( $inst, "mkdir /mnt/var" );
                emit_line( $inst, "mount $partition /mnt/var" );
            }
            when ('dev') {
                emit_line( $inst, "mkdir /mnt/dev" );
                emit_line( $inst, "mount $partition /mnt/dev" );
            }
            when ('sys') {
                emit_line( $inst, "mkdir /mnt/sys" );
                emit_line( $inst, "mount $partition /mnt/sys" );
            }
        }
    }

    emit( $inst, "\n" );

    emit_line( $inst, "pacstrap /mnt base base-devel" );

    if ($wirelesstools) {
        emit_line( $inst,
            "pacstrap /mnt wireless_tools netcfg wpa_supplicant wpa_actiond" );
    }

    if ( defined $bootloader ) {
        given ($bootloader) {
            when ('grub') {
                emit_line( $inst, "pacstrap /mnt grub-bios" );
            }
            when ('syslinux') {
                emit_line( $inst, "pacstrap /mnt syslinux" );
            }
        }
    }

    emit( $inst, "\n" );

    emit_line( $inst, "genfstab -p /mnt >> /mnt/etc/fstab" );

    emit( $inst, "\n" );

    emit_line( $inst, "mkdir -p /mnt/etc/archiso/" );
    emit_line( $inst, "cp /etc/archiso/functions /mnt/etc/archiso/functions" );

    emit_line( $inst, "cp $install_script /mnt/$install_script" );
    emit_line( $inst, "arch-chroot /mnt /$install_script --configure" );

    emit( $inst, "\n" );

    # unmount

    foreach (@partition_table) {
        my ( $dsk, $mount, $fs, $size ) = split /:/;
        given ($mount) {
            when ('boot') {
                emit_line( $inst, "umount /mnt/boot" );
            }
            when ('home') {
                emit_line( $inst, "umount /mnt/home" );
            }
            when ('usr') {
                emit_line( $inst, "umount /mnt/usr" );
            }
            when ('var') {
                emit_line( $inst, "umount /mnt/var" );
            }
            when ('dev') {
                emit_line( $inst, "umount /mnt/dev" );
            }
            when ('sys') {
                emit_line( $inst, "umount /mnt/sys" );
            }
        }
    }

    emit_line( $inst, "umount /mnt" );

    emit_line( $inst,
"echo \"Installation was a success. You may reboot into you new system\""
    );

    emit_line( $inst, "\n\nelse # This part runs in chroot\n\n" );

    # setup vconsole.conf

    emit_line( $inst, "echo \"KEYMAP=$keymap\" > /etc/vconsole.conf" );
    emit_line( $inst, "echo \"FONT=$font\" >> /etc/vconsole.conf" );
    emit_line( $inst, "echo \"FONT_MAP=$fontmap\" >> /etc/vconsole.conf" );

    emit( $inst, "\n" );

	my ( $in, $out );
	
    #setup mirrorlist

    if (@mirrors) {
        open( $in,  "<", $mirrorlist );
        open( $out, ">", "./mirrorlist" );

        my $found;
        while ( my $line = <$in> ) {
            if ( $line =~ /^\s*$/ ) {
                print $out $line;
                next;
            }
            $found = 0;
            foreach (@mirrors) {
                $_ = ( split( /\s/, $_ ) )[-1];
                if ( index( $line, $_ ) != -1 ) {
                    $found = 1;
                    $line =~ s/^[#\s]+//;
                    print $out $line;
                    last;
                }
            }

            if ( !$found ) {
                if   ( $line !~ /^#/ ) { print $out "#$line"; }
                else                   { print $out $line; }
            }
        }

        close $in;
        close $out;

        open MIRRORFILE, './mirrorlist';
        emit_line( $inst, "cat > $mirrorlist << 'EOF'" );
        while (<MIRRORFILE>) {
            emit( $inst, $_ );
        }
        close MIRRORFILE;
        emit_line( $inst, "EOF" );
        unlink('./mirrorlist');
    }    

    # setup locale

    open( $in,  "<", $locale_gen );
    open( $out, ">", './locale.gen' );

    my $found;
    while ( my $line = <$in> ) {
        $found = 0;
        if ( $line =~ /^#*[a-z]{2,3}_/ ) {
            foreach (@locales) {
                if (   index( $line, $_ ) != -1
                    or index( $line, $locale_lang ) != -1 )
                {
                    $found = 1;
                    $line =~ s/^[#\s]+//;
                    print $out $line;
                    last;
                }
            }
        }

        if ( !$found ) {
            if   ( $line !~ /^#/ ) { print $out "#$line"; }
            else                   { print $out $line; }
        }
    }

    close $in;
    close $out;

    emit( $inst, "\n" );

    open LOCFILE, './locale.gen';
    emit_line( $inst, "cat > $locale_gen << 'EOF'" );
    while (<LOCFILE>) {
        emit( $inst, $_ );
    }
    close LOCFILE;
    emit_line( $inst, 'EOF' );
    unlink('./locale.gen');

    emit_line( $inst, "locale-gen" );

    emit( $inst, "\n" );

    emit_line( $inst, "echo \"LANG=$locale_lang\" > /etc/locale.conf" );
    emit_line( $inst, "echo \"LC_MESSAGES=C\" >> /etc/locale.conf" );
    if ( defined $locale_time ) {
        emit_line( $inst, "echo \"LC_TIME=$locale_time\" >> /etc/locale.conf" );
    }

    emit_line( $inst, "ln -s /usr/share/zoneinfo/$timezone /etc/localtime" );

    # setup hostname/hosts

    if ( defined($hostname) ) {
        emit_line( $inst, "echo \"$hostname\" > /etc/hostname" );

        emit_line( $inst,
"echo \"127.0.0.1    localhost.localdomain   localhost   $hostname\" > /etc/hosts"
        );
        emit_line( $inst,
"echo \"::1          localhost.localdomain   localhost   $hostname\" >> /etc/hosts"
        );

        if ($static_ip) {
            emit_line( $inst,
                "echo \"$ip  $hostname.$domain   $hostname\" >> /etc/hosts" );
        }
    }

    emit( $inst, "\n" );

    # setup rc.conf

    open( $in,  "<", $rc_conf );
    open( $out, ">", './rc.conf' );

    while ( my $line = <$in> ) {
        if ( $line =~ /^[#\s]*interface=/ and defined($interface) ) {
            print $out "interface=$interface\n";
        }
        elsif ( $line =~ /^[#\s]*address=/
            and defined $interface
            and $static_ip )
        {
            print $out "address=$ip\n";
        }
        elsif ( $line =~ /^[#\s]*netmask=/
            and defined $interface
            and $static_ip )
        {
            print $out "netmask=$netmask\n";
        }
        elsif ( $line =~ /^[#\s]*gateway=/
            and defined $interface
            and $static_ip )
        {
            print $out "gateway=$gateway\n";
        }
        else {
            print $out $line;
        }
    }

    close $in;
    close $out;

    open RCFILE, './rc.conf';
    emit_line( $inst, "cat > $rc_conf << 'EOF'" );
    while (<RCFILE>) {
        emit( $inst, $_ );
    }
    close RCFILE;
    emit_line( $inst, 'EOF' );
    unlink('./rc.conf');

    # setup hardware clock

    if ($use_localtime) {
        emit_line( $inst, "hwclock --systohc --localtime" );
    }
    else {
        emit_line( $inst, "hwclock --systohc --utc" );
    }

    # create initial ramdisk

    emit_line( $inst, "mkinitcpio -p linux" );

    # install bootloader

    if ( defined $bootloader ) {
        given ($bootloader) {
            when ('grub') {
                emit_line( $inst, "grub-install $bootloader_disk" );
                emit_line( $inst,
"cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo"
                );
                emit_line( $inst, "grub-mkconfig -o /boot/grub/grub.cfg" );
            }
            when ('syslinux') {
                emit_line( $inst, "/usr/sbin/syslinux-install_update -iam" );
            }
        }
    }

    emit_line( $inst, "passwd" );

    emit_line( $inst, "fi" );

    close $inst;

    chmod 0755, $install_script;

    return ( 0, 'Installation script generated successfully' );
}
1
__END__
