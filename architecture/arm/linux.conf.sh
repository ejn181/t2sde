# --- T2-COPYRIGHT-NOTE-BEGIN ---
# T2 SDE: architecture/arm/linux.conf.sh
# Copyright (C) 2009 - 2022 The T2 SDE Project
# 
# This Copyright note is generated by scripts/Create-CopyPatch,
# more information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2.
# --- T2-COPYRIGHT-NOTE-END ---

if [ -f .config.defconfig ]; then
	cat .config.defconfig
elif [ -f $base/architecture/$arch/linux.conf.m4 ]; then
	m4 -I $base/architecture/$arch -I $base/architecture/share $base/architecture/$arch/linux.conf.m4
	[ "$SDECFG_ARM_ENDIANESS" = "eb" ] &&
		echo CONFIG_CPU_BIG_ENDIAN=y || echo CONFIG_CPU_LITTLE_ENDIAN=y
fi
