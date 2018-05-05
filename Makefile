
.PHONY: all clean distclean


all: efiboot.iso


boot/vmlinuz:
	@rm -f "$(@)"
	@mkdir -p boot
	curl \
	   -o "$(@)" \
	   https://mirrors.kernel.org/slackware/slackware64-current/kernels/huge.s/bzImage \
	   || { rm -f "$(@)"; exit 1; }
	@touch "$(@)"


boot/initrd.img:
	@rm -f "$(@)"
	@mkdir -p boot
	curl \
	   -o "$(@)" \
	   https://mirrors.kernel.org/slackware/slackware64-current/isolinux/initrd.img \
	   || { rm -f "$(@)"; exit 1; }
	@touch "$(@)"


EFI/BOOT/bootx64.efi: Makefile grub-stub.cfg
	@mkdir -p EFI/BOOT
	grub-mkimage \
	   -o $(@) \
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
	   linux \
	   || { rm -f "$(@)"; exit 1; }
	@touch "$(@)"


EFI/BOOT/efiboot.img: EFI/BOOT/bootx64.efi
	@rm -f "$(@)"
	dd \
	   if=/dev/zero \
	   of="$(@)" \
	   bs=512 \
	   count=2880 \
	   || { rm -f "$(@)"; exit 1; }
	mkfs.msdos \
	   -F 12 \
	   -n 'EFIBOOTISO' \
	   "$(@)" \
	   || { rm -f "$(@)"; exit 1; }
	mmd \
	   -i "$(@)" \
	   ::EFI \
	   || { rm -f "$(@)"; exit 1; }
	mmd \
	   -i "$(@)" \
	   ::EFI/BOOT \
	   || { rm -f "$(@)"; exit 1; }
	mcopy \
	   -i "$(@)" \
	   EFI/BOOT/bootx64.efi \
	   ::EFI/BOOT/bootx64.efi \
	   || { rm -f "$(@)"; exit 1; }
	@touch "$(@)"


syslinux/isolinux.bin.mod: /usr/share/syslinux/isolinux.bin
	@mkdir -p syslinux
	cp /usr/share/syslinux/isolinux.bin "$(@)"
	@touch "$(@)"


boot/grub/x86_64-efi/efiboot.copied:
	@rm -Rf "boot/grub/x86_64-efi"
	@mkdir -p "boot/grub/x86_64-efi"
	cp /usr/lib64/grub/x86_64-efi/*.mod \
	   "boot/grub/x86_64-efi/" \
	   || { rm -f "$(@)"; exit 1; }
	@touch "$(@)"


efiboot.iso: EFI/BOOT/efiboot.img syslinux/isolinux.bin.mod boot/grub/x86_64-efi/efiboot.copied boot/initrd.img boot/vmlinuz grub.cfg
	mkisofs \
	   -o "$(@)" \
	   -R -J -v -d -N \
	   -x '.git' \
	   -x efiboot.iso \
	   -hide-rr-moved \
	   -no-emul-boot \
	   -boot-load-size 4 \
	   -boot-info-table \
	   -b syslinux/isolinux.bin.mod \
	   -c syslinux/isolinux.boot \
	   -eltorito-alt-boot \
	   -no-emul-boot \
	   -eltorito-platform efi \
	   -eltorito-boot EFI/BOOT/efiboot.img \
	   -V "EFIBOOTISO" \
	   -A "EFI Boot ISO Example"  \
	   ./ \
	   || { rm -f "$(@)"; exit 1; }
	@touch "$(@)"


clean:
	rm -f efiboot.iso
	rm -Rf syslinux EFI


distclean: clean
	rm -Rf boot


