#!/usr/bin/env bash

# Params
params () {
  debug=true
  show_status=true
  show_cmd_output=false
  nuke=false
  devel=true
  grub=false
  bootctl=true
  hostname='test'
  passwd_vagrant='vagrant'
  passwd_root='root'
  if [[ -z $noop ]]; then noop=false; fi
  volgroupname="vg_${hostname}"
  lvs='root:3G var:4G swap:1G home:1G'
}


prepare_disk () {
  if $show_status; then echo "Status: Detecting the disks, will exit if uncertain";fi
  # Get the available physical disks
  disks=$( /usr/bin/lsblk | /usr/bin/grep disk | cut -d ' ' -f1)
  if $debug; then echo "Debug: Disks detected: $disks"; fi
  # Check if there is only one, otherwise quit
  disk_amount=0
  for disk in $disks; do
    disk_amount=$(( $disk_amount + 1 ))
    disks_available="${disk},"
  done
  if [[ $disk_amount -ne 1 ]];then
    message="Not certain on disk to use, disks available: ${disks_available}."
    exitstatus='2'
    quit
  else
    disk_to_use="/dev/$disks"
  fi

  if $show_status; then echo "Status: Detected disk: $disk_to_use"; fi

  if $show_status; then echo "Status: Clean up disk: $disk_to_use"; fi
  # Destroy the GPT data stuckures
  cmd="/usr/bin/sdgisk --zap $disk_to_use"
  if $noop; then echo "Debug: $cmd"; else
    /usr/bin/sgdisk --zap $disk_to_use
  fi
  # Clean the disk
  if $nuke; then
    cmd="/usr/bin/dd if=/dev/zero of=${disk_to_use} bs=512 status=progress"
    if $noop; then echo "Debug: $cmd"; else
      if $show_status; then
        $cmd
      else
        /usr/bin/dd if=/dev/zero of=${disk_to_use} bs=512
      fi
    fi
  fi
  # Reload the disk
  if $show_status; then echo "Status: Reloading the disk"; fi
  cmd="/usr/bin/partprobe $disk_to_use"; cmd_succuss='0'; do_cmd
}

partition_lvm () {
  if $show_status; then echo "Status: Partitioning disk $disk_to_use"; fi
  if $show_status; then echo "Status: Creating /dev/sda1"; fi
  if $grub; then
    cmd="/usr/bin/sgdisk $disk_to_use --new=1:0:+200M"; cmd_success='0'; do_cmd
    if $show_status; then echo "Status: Set /dev/sda1 type to ef02"; fi
    cmd="/usr/bin/sgdisk ${disk_to_use} --typecode=1:ef02"; cmd_success='0'; do_cmd
  elif $bootctl; then
    cmd="/usr/bin/sgdisk $disk_to_use --new=1:0:+512M"; cmd_success='0'; do_cmd
    if $show_status; then echo "Status: Set /dev/sda1 type to ef00"; fi
    cmd="/usr/bin/sgdisk ${disk_to_use} --typecode=1:EF00"; cmd_success='0'; do_cmd
  fi
  if $show_status; then echo "Status: Make /dev/sda1 bootable"; fi
  cmd="/usr/bin/sgdisk ${disk_to_use} --attributes=1:set:2"; cmd_success='0'; do_cmd
  if $show_status; then echo "Status: Creating /dev/sda2"; fi
  cmd="/usr/bin/sgdisk $disk_to_use --new=2:0:0"; cmd_success='0'; do_cmd
  if $show_status; then echo "Status: Set /dev/sda2 type to 8e00"; fi
  cmd="/usr/bin/sgdisk $disk_to_use --typecode=2:8E00"; cmd_success='0'; do_cmd
  if $show_status; then echo "Status: Creating pv"; fi
  cmd="/usr/bin/pvcreate /dev/sda2"; cmd_success='0'; do_cmd
  if $show_status; then echo "Status: Creating vg"; fi
  cmd="/usr/bin/vgcreate $volgroupname /dev/sda2"; cmd_success='0'; do_cmd
  for lv in $lvs; do
    name=$( echo $lv | cut -d ':' -f1 )
    size=$( echo $lv | cut -d ':' -f2 )
    if $show_status; then echo "Status: Creating lv $name"; fi
    cmd="/usr/bin/lvcreate -L $size $volgroupname -n $name"; cmd_success='0'; do_cmd
  done
}

format_lvm () {
  if $show_status; then echo "Status: Format the boot disk"; fi
  cmd="/usr/bin/mkfs.vfat -F 32 ${disk_to_use}1"; cmd_success='0'; do_cmd
  if $show_status; then echo "Status: Format the disks"; fi
  for lv in $lvs; do
    name=$( echo $lv | cut -d ':' -f1 )
    cmd="/usr/bin/mkfs.ext4 /dev/mapper/${volgroupname}-${name}"; cmd_success='0'; do_cmd
  done
}

mount_lvm () {
  if $show_status; then echo "Status: Mounting /"; fi
  cmd="/usr/bin/mount /dev/mapper/${volgroupname}-root /mnt"; cmd_success='0'; do_cmd
  if $show_status; then echo "Status: Mounting /boot"; fi
  cmd="/usr/bin/mkdir -p /mnt/boot"; cmd_success='0'; do_cmd
  cmd="/usr/bin/mount ${disk_to_use}1 /mnt/boot"; cmd_success='0'; do_cmd
  remaining_volumes=$( /usr/bin/lvs | grep -v root | grep -v swap | grep $volgroupname | cut -d ' ' -f3 )
  for volume in $remaining_volumes; do
    cmd="/usr/bin/mkdir -p /mnt/$volume"; cmd_success='0'; do_cmd
    cmd="/usr/bin/mount /dev/mapper/${volgroupname}-${volume} /mnt/${volume}"; cmd_success='0'; do_cmd
  done
  if $show_status; then echo "Status: Check swap"; fi
  swap_included=$( /usr/bin/lvs | grep swap | grep $volgroupname | cut -d ' ' -f3 )
  if $debug; then echo "Debug: Swap: $swap_included"; fi
  if [[ ! -z $swap_included ]]; then
    cmd="/usr/bin/mkswap /dev/mapper/${volgroupname}-${swap_included}"; cmd_success='0'; do_cmd
    cmd="/usr/bin/swapon /dev/mapper/${volgroupname}-${swap_included}"; cmd_success='0'; do_cmd
  fi
}

execute_pacstrap () {
 if $show_status; then echo "Status: Executing pacstrap"; fi
 if $devel; then
   cmd="/usr/bin/pacstrap /mnt base base-devel"; cmd_success='0'; do_cmd
 else
   cmd="/usr/bin/pacstrap /mnt base"; cmd_success='0'; do_cmd
 fi
}

generate_fstab () {
  if $show_status; then echo "Status: Generate fstab"; fi
  cmd="/usr/bin/genfstab /mnt >> /mnt/etc/fstab"; cmd_success='0'; do_cmd
}

chroot_config () {
  if $show_status; then echo "Status: Set hostname"; fi
  cmd="echo '$hostname' > /etc/hostname"; cmd_success='0'; do_cmd_chroot
  if $show_status; then echo "Status: Set timezone"; fi
  cmd="ln -s /usr/share/zoneinfo/europe/brussels /etc/localtime"; cmd_success='0'; do_cmd_chroot
  locale_used=$( cat /mnt/etc/locale.gen | grep -v '#' )
  echo $locale_used
  if $show_status; then echo "Status: Generate locale"; fi
  cmd="locale-gen"; cmd_success='0'; do_cmd_chroot
  cmd="echo 'LANG=$locale_used' > /etc/locale.conf"; cmd_success='0'; do_cmd_chroot
  if $show_status; then echo "Status: Building mkinitcpio"; fi
  cmd=""
  cmd="mkinitcpio -p linux"; cmd_success='0'; do_cmd_chroot
}

network_config () {
  echo 'do network config'
}

bootloader_grub () {
  if $show_status; then echo "Status: Install grub";fi
  cmd="echo 'Y' | pacman -S grub"; cmd_success='0'; do_cmd_chroot
  cmd="grub-install --target=i386-pc ${disk_to_use}1"; cmd_success='0'; do_cmd_chroot
  cmd="grub-mkconfig -o /boot/grub/grub.cfg"; cmd_success='0'; do_cmd_chroot
}

bootloader_bootctl () {
  if $show_status; then echo "Status: Install bootctl";fi
  cmd="bootctl install"; cmd_success='0'; do_cmd_chroot
  if $show_status; then echo "Status: Setting up bootctl";fi
  cmd="echo 'default arch\ntimeout 4\neditor 0\n' > /boot/loader/loader.conf"; cmd_success='0'; do_cmd_chroot
  blkid_root=$( blkid -o value /dev/mapper/${volgroupname}-${swap_included} | head -n 1 )
  cmd="echo 'title  Arch Linux LVM\nlinux  /vmlinuz-linux\ninitrd  initramfs-linux.img\noptions root=UUID=${blkid_root} rw' > /boot/loader/entries/arch.conf"; cmd_success='0'; do_cmd_chroot
}

create_vagrant_user () {
  if $show_status; then echo "Status: Adding the vagrant user"; fi
  cmd="/usr/bin/useradd -d /home/vagrant -G wheel -m vagrant"; cmd_success='0'; do_cmd_chroot
  if $show_status; then echo "Status: Setting user vagrant password to $passwd_vagrant"; fi
  cmd="echo 'vagrant:${passwd_vagrant}' | chpasswd"; cmd_success='0'; do_cmd_chroot
  if $show_status; then echo "Status: Configuring sudo for vagrant user"; fi
  cmd="echo 'Defaults:vagrant !requiretty\n  vagrant ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/10_vagrant"; cmd_success='0'; do_cmd_chroot
}

set_root_passwd () {
  if $show_status; then echo "Status: Setting user root password to $passwd_root"; fi
  cmd="echo 'root:${passwd_root}' | chpasswd"; cmd_success='0'; do_cmd_chroot
}

umount_volumes () {
  if $show_status; then echo "Status: Unmount the root"; fi
  cmd="/usr/bin/umount -R /mnt"; cmd_success='0'; do_cmd
}

crypt_passwd () {
  crypt_passwd=$( openssl passwd -crypt $1 )
  return $crypt_passwd
}

do_cmd () {
  if $noop; then echo "Noop: $cmd"; else
    if $show_cmd_output; then
      $cmd
      cmd_exit=$?; check_cmd
    else
      $cmd >> /dev/null
      cmd_exit=$?; check_cmd
    fi
  fi
}

do_cmd_chroot () {
  if $noop; then echo "Noop: $cmd"; else
    if $show_cmd_output; then
      $cmd
      cmd_exit=$?; check_cmd
    else
      echo "$cmd" | arch-chroot /mnt /bin/bash >> /dev/null
      cmd_exit=$?; check_cmd
    fi
  fi
}

check_cmd () {
  if [[ ! "$cmd_success" == "skip" ]];then
    if [[ "$cmd_success" -ne "$cmd_exit" ]]; then
      message="Somehting went wrong with '$cmd'"
      quit
    fi
  fi
}

quit () {
  # Default to unknown status
  if [[ -z $exitstatus ]]; then
    exitstatus=3
  fi
  if [[ "$exitstatus" -eq "2" ]]; then
    message="Error: ${message}"
  elif [[ "$exitstatus" -eq "1" ]]; then
    message="Warning: ${message}"
  else
    message="Unknown: ${message}"
    sleep 30
  fi
  echo "$message" && exit $exitcode
}

while test -n "$1"
do
  case "$1" in
    --help|-h)
      message="Usage: $0 --directory|-d </path/to/directory> --min-amount|-m <minimum amount>"
      exitcode=1
      quit
      shift
      ;;
    --noop)
      shift
      noop=$1
      shift
      ;;
    *)
      quit
      ;;
  esac
done

params
prepare_disk
partition_lvm
format_lvm
mount_lvm
execute_pacstrap
generate_fstab
chroot_config
if $grub; then
  bootloader_grub
elif $bootctl; then
  bootloader_bootctl
fi
create_vagrant_user
set_root_passwd
umount_volumes
