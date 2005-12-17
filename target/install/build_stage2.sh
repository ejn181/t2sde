# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: target/bootdisk/build_stage2.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

. $base/misc/target/functions.in

set -e

echo_header "Creating 2nd stage filesystem:"
mkdir -p $disksdir/2nd_stage
rm -rf $diskdir/2nd_stage/*
cd $disksdir/2nd_stage

#
package_map='00-dirtree
glibc
lilo               yaboot             aboot              grub
silo               parted             mac-fdisk          pdisk
xfsprogs           mkdosfs            jfsutils
e2fsprogs          reiserfsprogs      reiser4progs       genromfs
popt               raidtools          mdadm
lvm                lvm2               device-mapper
dump               eject              disktype
hdparm             memtest86          cpuburn            bonnie++
ncurses            readline
bash               attr               acl                findutils
mktemp             coreutils          pciutils
grep               sed                gzip               bzip2
tar                gawk               lzo                lzop
less               nvi                bc                 cpio
ed                 zile
curl               wget               dialog             minicom
lrzsz              rsync              tcpdump            module-init-tools
sysvinit           shadow             util-linux         wireless-tools
net-tools          procps             psmisc
modutils           pciutils           portmap
sysklogd           setserial          iproute2
netkit-base        netkit-ftp         netkit-telnet      netkit-tftp
sysfiles           libpcap            iptables           tcp_wrappers
kbd		   ntfsprogs
libol              hotplug++          memtester
serpnp             udev
openssl            openssh            iproute2'

if pkginstalled mine ; then
	packager=mine
else
	packager=bize
fi

package_map=" $( echo "$packager $package_map" | tr '\n' ' ' | tr '\t' ' ' | tr -s ' ' ) "

echo_status "Copying files."
for pkg in `grep '^X ' $base/config/$config/packages | cut -d ' ' -f 5`; do
	# include the package?
	#echo maybe $pkg >&2
	if [ "${package_map/ $pkg /}" != "$package_map" ]; then
		cut -d ' ' -f 2 $build_root/var/adm/flists/$pkg
	fi
done | (
	# quick and dirty filter
	grep  -v -e 'lib/[^/]*\.\(a\|la\|o\)$' -e 'var/\(adm\|games\|mail\|opt\)' \
	         -e 'usr/\(local\|doc\|man\|info\|games\|share\|include\|src\)' \
	         -e 'usr/.*-linux-gnu' -e '/gconv/' -e '/locale/' -e '/pkgconfig/' \
	         -e '/init.d/' -e '/rc.d/'
	# TODO: usr/lib/*/
) > ../files-wanted

copy_with_list_from_file $build_root $PWD $PWD/../files-wanted
copy_and_parse_from_source $base/target/install/rootfs $PWD

mkdir -p mnt/source mnt/target
du -csh

#	usr/share/terminfo/a/ansi usr/share/terminfo/l/linux \
#	usr/share/terminfo/n/nxterm usr/share/terminfo/x/{xterm,xterm-new} \
#	usr/share/terminfo/v/vt{100,200,220} \
#	usr/share/terminfo/s/screen

#		usr/share/kbd/keymaps/i386/{include,qwerty,qwertz} \
#		usr/share/kbd/keymaps/include
#	find usr/share/kbd -name '*dvo*' -o -name '*az*' -o -name '*fgG*' | \
#		xargs rm -f

#		usr/share/pci.ids

exit

echo_status "Creating 2nd stage linuxrc."
cp $base/target/$target/linuxrc2.sh linuxrc ; chmod +x linuxrc
cp $base/target/$target/shutdown sbin/shutdown ; chmod +x sbin/shutdown
echo '$STONE install' > etc/stone.d/default.sh
#
echo_status "Creating 2nd_stage.tar.gz archive."
tar -czf ../2nd_stage.tar.gz * ; cd ..


echo_header "Creating small 2nd stage filesystem:"
mkdir -p 2nd_stage_small ; cd 2nd_stage_small
mkdir -p dev proc tmp bin lib etc share
mkdir -p mnt/source mnt/target
ln -s bin sbin ; ln -s . usr

#

progs="agetty bash cat cp date dd df ifconfig ln ls $packager mkdir mke2fs \
       mkswap mount mv rm reboot route sleep swapoff swapon sync umount \
       eject chmod chroot grep halt rmdir sh shutdown uname killall5 \
       stone mktemp sort fold sed mkreiserfs cut head tail disktype"

progs="$progs fdisk sfdisk"

if [ $arch = ppc ] ; then
	progs="$progs mac-fdisk pdisk"
fi

if [ $packager = bize ] ; then
	progs="$progs bzip2 md5sum"
fi

echo_status "Copy the most important programs ..."
for x in $progs ; do
	fn=""
	[ -f ../2nd_stage/bin/$x ] && fn="bin/$x"
	[ -f ../2nd_stage/sbin/$x ] && fn="sbin/$x"
	[ -f ../2nd_stage/usr/bin/$x ] && fn="usr/bin/$x"
	[ -f ../2nd_stage/usr/sbin/$x ] && fn="usr/sbin/$x"

	if [ "$fn" ] ; then
		cp ../2nd_stage/$fn $fn
	else
		echo_error "\`- Program not found: $x"
	fi
done

#

echo_status "Copy the required libraries ..."
found=1 ; while [ $found = 1 ]
do
	found=0
	for x in ../2nd_stage/lib ../2nd_stage/usr/lib
	do
		for y in $( cd $x ; ls *.so.* 2> /dev/null )
		do
			if [ ! -f lib/$y ] &&
			   grep -q $y bin/* lib/* 2> /dev/null
			then
				echo_status "\`- Found $y."
				cp $x/$y lib/$y ; found=1
			fi
		done
	done
done
#
echo_status "Copy linuxrc."
cp ../2nd_stage/linuxrc .
echo_status "Copy /etc/fstab."
cp ../2nd_stage/etc/fstab etc
echo_status "Copy stone.d."
mkdir -p etc/stone.d
for i in gui_text mod_install mod_packages mod_gas default ; do
	cp ../2nd_stage/etc/stone.d/$i.sh etc/stone.d
done
#
echo_status "Creating links for identical files."
while read ck fn
do
	if [ "$oldck" = "$ck" ] ; then
		echo_status "\`- Found $fn -> $oldfn."
		rm $fn ; ln $oldfn $fn
	else
		oldck=$ck ; oldfn=$fn
	fi
done < <( find -type f | xargs md5sum | sort )
#
echo_status "Creating 2nd_stage_small.tar.gz archive."
tar -cf- * | gzip -9 > ../2nd_stage_small.tar.gz ; cd ..

