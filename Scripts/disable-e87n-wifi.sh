#!/bin/bash
# Force-disable Wi-Fi packages after `make defconfig` for the wired-only E87N.
set -euo pipefail

CFG="${1:-.config}"
[ -f "$CFG" ] || { echo "missing $CFG"; exit 1; }

wifi_pkgs=(
  wpad wpad-basic wpad-basic-mbedtls wpad-basic-openssl wpad-basic-wolfssl
  wpad-mbedtls wpad-openssl wpad-wolfssl wpad-mesh-mbedtls wpad-mesh-openssl
  hostapd hostapd-common hostapd-basic hostapd-openssl hostapd-utils
  wpa-supplicant wpa-supplicant-basic wpa-supplicant-mesh-openssl
  wpa-cli wpa-supplicant-openssl
  kmod-mac80211 kmod-cfg80211 kmod-mac80211-hwsim
  kmod-mt76 kmod-mt76-core kmod-mt76-connac kmod-mt76-usb
  kmod-mt7603 kmod-mt7615-common kmod-mt7615e kmod-mt7615-firmware
  kmod-mt7622 kmod-mt7663-firmware-ap kmod-mt7663-usb-sdio
  kmod-mt76x0e kmod-mt76x0u kmod-mt76x2e kmod-mt76x2u
  kmod-mt7915e kmod-mt7915-firmware kmod-mt7916-firmware
  kmod-mt7921e kmod-mt7921-firmware kmod-mt7922-firmware
  kmod-mt7996e kmod-mt7996-firmware kmod-mt7996-233-firmware
  iw iwinfo wireless-regdb wifi-scripts
  mt7981-wo-firmware mt7986-wo-firmware mt7988-2p5g-phy-firmware
)

for pkg in "${wifi_pkgs[@]}"; do
  # Drop any selected form, then mark unset
  sed -i "/^CONFIG_PACKAGE_${pkg}=/d" "$CFG"
  sed -i "/^# CONFIG_PACKAGE_${pkg} is not set$/d" "$CFG"
  echo "# CONFIG_PACKAGE_${pkg} is not set" >> "$CFG"
done

# Also clear any leftover mt76/mac80211/hostapd/wpad selections
sed -i -E '/^CONFIG_PACKAGE_(kmod-mt76|kmod-mt79|kmod-mac80211|kmod-cfg80211|wpad|hostapd|wpa-|iw|iwinfo|wireless-regdb|wifi-scripts|mt798.-wo-firmware)/d' "$CFG"

echo "E87N Wi-Fi packages force-disabled in $CFG"
