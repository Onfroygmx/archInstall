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
exec > >(tee -a ${log_full} )
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

    partition_delete $drive
    partition_drive $drive
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

}
install_arch "$@"
