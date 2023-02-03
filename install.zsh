#!/usr/bin/env zsh
#!/bin/zsh
#    ___           _        _ _
#   |_ _|_ __  ___| |_ __ _| | |
#    | || '_ \/ __| __/ _` | | |
#    | || | | \__ \ || (_| | | |
#   |___|_| |_|___/\__\__,_|_|_|
#


fpath+="${0:A:h}/fn"

## Autoload zsh modules when they are referenced
#################################################
autoload -U colors && colors
autoload -Uz $fpath[-1]/*(.:t)

current_dir="${0:A:h}"

pck_install=$current_dir/pkgInstall.txt
pck_installOba=$current_dir/pkgInstallObarun.txt
pck_installBtrfs=$current_dir/pkgInstallBtrfs.txt
typeset -a extrapkg

log_full=$current_dir/log_full_install.log
log_err=$current_dir/log_err_install.log

## Drive to use
drive="/dev/sda"

## Debug:
# echo $fpath >> $log_full
# echo $fpath[-1]/*(.:t) >> $log_full
# exec > >(tee -a ${log_full} )
exec 2> >(tee -a ${log_err} >&2)

case $1 in
  ($'oba'*)
    archsys="oba"
  ;;
  *)
    archsys="arch"
  ;;
esac

case $2 in
  "btrfs")
    archfs=$2
  ;;
  *)
    archfs="ext4"
  ;;
esac

function install_arch {

    printf "\n$fg[green]Installation of Archlinux will start:$reset_color\n\n"
    printf "\n$fg[yellow]Sytem:\t\t$archsys$reset_color"
    printf "\n$fg[yellow]Drive:\t\t$drive$reset_color"
    printf "\n$fg[yellow]FilesSytem:\t$archfs$reset_color\n"

    partition_delete
    partition_drive
    ## Call external function for formating
    partition_format /dev/sda1 fat boot
    partition_format /dev/sda2 $archfs home
    partition_format /dev/sda3 $archfs root

    partition_mount /dev/sda3

    printf "$fg[green]Partitions:$reset_color\n\n"

    lsblk -f

    printf "$fg[green]Prepare Pacman$reset_color\n\n"
    #prepare_pacman $pck_install
    prepare_pacman

    printf "$fg[cyan]Pacstrap Installation$reset_color\n\n"
    pacstrap /mnt base linux linux-firmware $extrapkg - < $pck_install

    genfstab -t PARTUUID -p /mnt >> /mnt/etc/fstab

    printf "$fg[green]Base Installation done, now we will proceed with basic setup before reboot$reset_color\n\n"

    setup_etckeeper


    # Setup locale to en-us-utf-8 and keyboard to be-latin1
    setup_locale
    arch-chroot /mnt locale-gen
    case $archsys in
      ($'oba'*)
        printf "$fg[green]For Obarun locale is set during tree setup$reset_color\n\n"
      ;;
      *)
        arch-chroot /mnt localectl status
        arch-chroot /mnt etckeeper commit "Configure locale and keyboard"
      ;;
    esac

    # Setup timedate
    case $archsys in
      ($'oba'*)
        printf "$fg[green]For Obarun timedate is set during tree setup$reset_color\n\n"
      ;;
      *)
        arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
        arch-chroot /mnt timedatectl set-timezone Europe/Paris
        arch-chroot /mnt timedatectl set-ntp true
        arch-chroot /mnt hwclock --systohc --utc
        arch-chroot /mnt timedatectl status
        arch-chroot /mnt etckeeper commit "Configure Date/Time and synchronization"
      ;;
    esac

    # Setup network: hostname, resolve, dhcp
    setup_network $archsys
    case $archsys in
      ($'oba'*)
        printf "$fg[green]For Obarun network is set during tree setup$reset_color\n\n"
      ;;
      *)
        arch-chroot /mnt hostnamectl set-hostname arch
        arch-chroot /mnt hostnamectl status
        arch-chroot /mnt etckeeper commit "Configure Network files"
      ;;
    esac

    setup_systemd_bootloader

    user_root
    arch-chroot /mnt etckeeper commit "Configure Boot loader and root user"

    ### Copy pacman configs to new setup
#rerun pacman preparation during setup    #cp /etc/pacman.conf /mnt/etc/
    cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

    ### Configuration files for network
    cp conf/etc/systemd/network/10-* /mnt/etc/systemd/network/
    arch-chroot /mnt chmod 644 /etc/systemd/network/10-*

    ### Set a welcome motd
    cp conf/etc/profile.d/archmotd.sh /mnt/etc/profile.d/

    setup_config
    arch-chroot /mnt etckeeper commit "Configure other base functionalities"

}
install_arch "$@"
