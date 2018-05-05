
EFI Boot ISO Example
====================

This is a simple example of how to create a bootable ISO for a computer using
UEFI. A makefile is included which automates the downloading of a test Linux
kernel and initfs (Slackware current 64bit) and generating the bootable ISO and
requisite files/images using the base tools.


The general flow of creating a bootable ISO for UEFI systems is:

   1. Create an UEFI Grub image with a stub config and minimal modules.
   2. Create a vfat image file to use as the UEFI ESP (EFI System Partition).
   3. Create the ISO with the kernel images, ESP image file, Grub modules, and
      full  using mkisofs.


Create directory structure and download files
--------------------------

Create directories and change CWD:

    mkdir -p efibootiso
    cd efibootiso
    mkdir -p EFI/BOOT
    mkdir -p boot/grub/x86_64-efi

Download Slackware files:

    curl \
       -o boot/vmlinuz \
       https://mirrors.kernel.org/slackware/slackware64-current/kernels/huge.s/bzImage
    curl \
       -o boot/initrd.img \
       https://mirrors.kernel.org/slackware/slackware64-current/isolinux/initrd.img


Create bootx64.efi
------------------

Copy grub modules:

    cp /usr/lib64/grub/x86_64-efi/*.mod boot/grub/x86_64-efi/

Create stub grub configuration:

    cat << EOF > grub-stub.cfg
    
    insmod all_video
    insmod efi_gop
    insmod efi_uga
    insmod video_bochs
    insmod video_cirrus
    
    insmod iso9660
    insmod udf
    
    search --no-floppy --label EFIBOOTISO --set root
    set prefix=($root)/boot/grub
    
    configfile /grub.cfg
    
    EOF

Create grub image:

    grub-mkimage \
       -o EFI/BOOT/bootx64.efi \
       -c grub-stub.cfg \
       -p /boot/grub \
       -O x86_64-efi \
       efi_gop efi_uga efinet \
       all_video video video_bochs video_cirrus video_fb videoinfo \
       serial \
       terminfo terminal \
       search search_fs_file search_fs_uuid search_label \
       udf iso9660 ext2 fat exfat ntfs hfsplus \
       part_gpt part_msdos msdospart lvm diskfilter parttool probe \
       normal \
       acpi ohci uhci ahci ehci \
       cat ls chain configfile echo halt reboot \
       ls lsefimmap lsefisystab lsmmap lspci lsacpi lssal \
       linux


Create UEFI ESP (EFI System Partition) Image
--------------------------------------------

Create empty file to use as disk image:

    dd if=/dev/zero of=EFI/BOOT/efiboot.img bs=512 count=2880

Create MSDOS filesystem:

    mkfs.msdos -F 12 -n 'EFIBOOTISO' EFI/BOOT/efiboot.img

Create directory structure:

    mmd -i EFI/BOOT/efiboot.img ::EFI
    mmd -i EFI/BOOT/efiboot.img ::EFI/BOOT

Copy grub image into disk image file:

    mcopy -i EFI/BOOT/efiboot.img EFI/BOOT/bootx64.efi ::EFI/BOOT/bootx64.efi


Create UEFI bootable ISO image
------------------------------

Create full grub configuration:

    cat << EOF > grub.cfg
    
    serial --unit 4 --speed 9600
    terminal_input  serial console
    terminal_output serial console
    
    set pager=1
    
    menuentry --hotkey=l 'Linux' {
       echo   'Loading /boot/vmlinuz ...'
       linux  /boot/vmlinuz \
              console=tty0 \
              rw
       echo   'Loading /boot/initrd.img ...'
       initrd /boot/initrd.img
    }
    menuentry --hotkey=p 'List PCI' {
       lspci
    }
    menuentry --hotkey=r 'Reboot' {
       reboot
    }
    menuentry --hotkey=h 'Halt' {
       halt
    }
    
    EOF

Create ISO image with mkisofs:

    mkisofs \
       -o efiboot.iso \
       -R -J -v -d -N \
       -x efiboot.iso \
       -hide-rr-moved \
       -no-emul-boot \
       -eltorito-platform efi \
       -eltorito-boot EFI/BOOT/efiboot.img \
       -V "EFIBOOTISO" \
       -A "EFI Boot ISO Test"  \
       .


