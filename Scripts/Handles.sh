#!/bin/bash

PKG_PATH="$GITHUB_WORKSPACE/$WRT_DIR/package/"

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then
	echo " "

	HP_RULE="surge"
	HP_PATH="homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

	cd .. && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy date has been updated!"
fi

#修改argon主题字体和颜色
if [ -d "$PKG_PATH/luci-theme-argon" ]; then
	echo " "
	if sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" \
		"$PKG_PATH/luci-theme-argon/luci-app-argon-config/root/etc/config/argon"; then
		echo "theme-argon has been fixed!"
	else
		echo "theme-argon fix failed; continuing!"
	fi
fi

#修改aurora菜单式样
if [ -d "$PKG_PATH/luci-app-aurora-config" ]; then
	echo " "
	if find "$PKG_PATH/luci-app-aurora-config/root/usr/share/aurora/" -type f -name '*.template' -exec \
		sed -i "s/nav_type '.*'/nav_type 'dropdown'/g; s/struct_radius_base '.*'/struct_radius_base '0.125rem'/g" {} +; then
		echo "theme-aurora has been fixed!"
	else
		echo "theme-aurora fix failed; continuing!"
	fi
fi

#修改mini-diskmanager菜单位置
if [ -d "$PKG_PATH/luci-app-mini-diskmanager" ]; then
	echo " "
	if sed -i "s/services/system/g" \
		"$PKG_PATH/luci-app-mini-diskmanager/luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json"; then
		echo "mini-diskmanager has been fixed!"
	else
		echo "mini-diskmanager fix failed; continuing!"
	fi
fi

#修复TailScale配置文件冲突
FEEDS_PACKAGES="$PKG_PATH/../feeds/packages"
TS_FILE="$(find "$FEEDS_PACKAGES" -maxdepth 3 -type f -wholename '*/tailscale/Makefile' -print -quit 2>/dev/null)"
if [ -f "$TS_FILE" ]; then
	echo " "

	if sed -i '/\/files/d' "$TS_FILE"; then
		echo "tailscale has been fixed!"
	else
		echo "tailscale fix failed; continuing!"
	fi
fi

#修复Rust编译失败
RUST_FILE="$(find "$FEEDS_PACKAGES" -maxdepth 3 -type f -wholename '*/rust/Makefile' -print -quit 2>/dev/null)"
if [ -f "$RUST_FILE" ]; then
	echo " "

	if sed -i 's/ci-llvm=true/ci-llvm=false/g' "$RUST_FILE"; then
		echo "rust has been fixed!"
	else
		echo "rust fix failed; continuing!"
	fi
fi

# EdgePi E87N: apply board DTS overlay + immortalwrt patches from Yanw3n/imagebuilder
if [ "${WRT_CONFIG}" = "E87N" ]; then
	echo " "
	WRT_ROOT="$GITHUB_WORKSPACE/$WRT_DIR"
	OVERLAY="$GITHUB_WORKSPACE/device/edgepi-e87n/source-overlay"
	PATCHDIR="$GITHUB_WORKSPACE/patches/e87n"

	if [ -d "$OVERLAY" ]; then
		cp -a "$OVERLAY/." "$WRT_ROOT/"
		echo "E87N source overlay applied!"
	else
		echo "E87N overlay missing; continuing!"
	fi

	# Rootfs files (uci-defaults) from imagebuilder-style files/
	if [ -d "$GITHUB_WORKSPACE/files" ]; then
		mkdir -p "$WRT_ROOT/files"
		cp -a "$GITHUB_WORKSPACE/files/." "$WRT_ROOT/files/"
		echo "E87N rootfs files/ overlay applied!"
	fi

	if [ -d "$PATCHDIR" ]; then
		shopt -s nullglob
		for patch_file in "$PATCHDIR"/*.patch; do
			echo "Applying $(basename "$patch_file")..."
			if patch --batch --forward -d "$WRT_ROOT" -p1 < "$patch_file"; then
				echo "Applied $(basename "$patch_file")"
			else
				echo "Patch $(basename "$patch_file") failed or already applied; continuing!"
			fi
		done
		shopt -u nullglob
	else
		echo "E87N patch dir missing; continuing!"
	fi

	# platform_copy_config hunk may drift across immortalwrt revisions; ensure board is listed.
	PLAT="$WRT_ROOT/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh"
	if [ -f "$PLAT" ] && ! grep -q 'edgepi,e87n' "$PLAT"; then
		sed -i '/platform_copy_config()/,/^}/ {
			/glinet,gl-xe3000|/a\\tedgepi,e87n|
		}' "$PLAT"
		echo "E87N inserted into platform_copy_config()"
	elif [ -f "$PLAT" ]; then
		echo "E87N already present in platform.sh"
	fi

	# Ensure Device/edgepi_e87n exists even if filogic.mk hunk context drifted
	FILO="$WRT_ROOT/target/linux/mediatek/image/filogic.mk"
	if [ -f "$FILO" ] && ! grep -q 'Device/edgepi_e87n' "$FILO"; then
		cat >> "$FILO" <<'EOF'

define Device/edgepi_e87n
  DEVICE_VENDOR := EdgePi
  DEVICE_MODEL := E87N
  DEVICE_DTS := mt7987a-edgepi-e87n
  DEVICE_DTS_DIR := ../dts
  BOARD_NAME := edgepi,e87n
  SUPPORTED_DEVICES += edgepi,e87n
  DEVICE_PACKAGES := kmod-hwmon-pwmfan kmod-usb3 kmod-nvme \
	kmod-phy-realtek mt7987-2p5g-phy-firmware f2fsck mkf2fs automount
  KERNEL_LOADADDR := 0x40000000
  KERNEL_SIZE := 32768k
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += edgepi_e87n
EOF
		echo "E87N device profile appended to filogic.mk"
	elif [ -f "$FILO" ] && grep -q 'Device/edgepi_e87n' "$FILO"; then
		# Patch may have applied an older profile; force stock board id + FIT recipe.
		if ! grep -q 'BOARD_NAME := edgepi,e87n' "$FILO"; then
			sed -i '/define Device\/edgepi_e87n/,/^endef$/ {
				/DEVICE_DTS_DIR := ..\/dts/a\  BOARD_NAME := edgepi,e87n\n  SUPPORTED_DEVICES += edgepi,e87n
			}' "$FILO"
			echo "E87N BOARD_NAME injected into existing filogic.mk profile"
		fi
		if ! grep -A20 'define Device/edgepi_e87n' "$FILO" | grep -q 'KERNEL := kernel-bin'; then
			sed -i '/define Device\/edgepi_e87n/,/^endef$/ {
				/KERNEL_SIZE := 32768k/a\  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb\n  KERNEL_INITRAMFS := kernel-bin | lzma | \\\n\tfit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
			}' "$FILO"
			echo "E87N KERNEL FIT recipe injected into existing filogic.mk profile"
		fi
		if ! grep -A20 'define Device/edgepi_e87n' "$FILO" | grep -q 'kmod-phy-realtek'; then
			sed -i '/define Device\/edgepi_e87n/,/^endef$/ {
				s/mt7987-2p5g-phy-firmware/kmod-phy-realtek mt7987-2p5g-phy-firmware/
			}' "$FILO"
			echo "E87N kmod-phy-realtek injected into DEVICE_PACKAGES"
		fi
	fi
fi
