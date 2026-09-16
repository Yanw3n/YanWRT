#!/bin/bash
# Force-disable Wi-Fi packages after `make defconfig` for the wired-only E87N.
# ImmortalWrt filogic DEFAULT_PACKAGES includes wpad-openssl; defconfig also
# falls back to DEFAULT_PROFILE=openwrt_one (Wi-Fi) if the device symbol is wrong.
set -euo pipefail

CFG="${1:-.config}"
[ -f "$CFG" ] || { echo "missing $CFG"; exit 1; }

wifi_pkgs=(
  wpad wpad-basic wpad-basic-mbedtls wpad-basic-openssl wpad-basic-wolfssl
  wpad-mbedtls wpad-openssl wpad-wolfssl wpad-mesh-mbedtls wpad-mesh-openssl
  wpad-mesh-wolfssl wpad-full wpad-full-openssl wpad-full-mbedtls
  hostapd hostapd-common hostapd-basic hostapd-openssl hostapd-utils
  hostapd-basic-openssl hostapd-basic-mbedtls hostapd-basic-wolfssl
  wpa-supplicant wpa-supplicant-basic wpa-supplicant-mesh-openssl
  wpa-cli wpa-supplicant-openssl wpa-supplicant-mesh-mbedtls
  eapol-test eapol-test-openssl eapol-test-mbedtls
  kmod-mac80211 kmod-cfg80211 kmod-mac80211-hwsim
  kmod-mt76 kmod-mt76-core kmod-mt76-connac kmod-mt76-usb
  kmod-mt7603 kmod-mt7615-common kmod-mt7615e kmod-mt7615-firmware
  kmod-mt7622 kmod-mt7663-firmware-ap kmod-mt7663-usb-sdio
  kmod-mt76x0e kmod-mt76x0u kmod-mt76x2e kmod-mt76x2u
  kmod-mt7915e kmod-mt7915-firmware kmod-mt7916-firmware
  kmod-mt7921e kmod-mt7921-firmware kmod-mt7922-firmware
  kmod-mt7996e kmod-mt7996-firmware kmod-mt7996-233-firmware
  iw iwinfo wireless-regdb wifi-scripts wifi-scripts-json
  mt7981-wo-firmware mt7986-wo-firmware mt7988-2p5g-phy-firmware
)

# Drop every selected wifi-related package symbol (broad net).
sed -i -E \
  '/^CONFIG_PACKAGE_(kmod-mt76|kmod-mt79|kmod-mac80211|kmod-cfg80211|wpad|hostapd|wpa-|eapol-test|iw|iwinfo|wireless-regdb|wifi-scripts|mt798[0-9]-wo-firmware)/d' \
  "$CFG"

for pkg in "${wifi_pkgs[@]}"; do
  sed -i "/^# CONFIG_PACKAGE_${pkg} is not set$/d" "$CFG"
  echo "# CONFIG_PACKAGE_${pkg} is not set" >> "$CFG"
done

# Hard fail if anything Wi-Fi related is still selected — catch it before a 90min compile.
leftover="$(grep -E '^CONFIG_PACKAGE_(kmod-mt76|kmod-mt79|kmod-mac80211|kmod-cfg80211|wpad|hostapd|wpa-|iwinfo|wireless-regdb|wifi-scripts).*=y' "$CFG" || true)"
if [ -n "$leftover" ]; then
  echo "ERROR: Wi-Fi packages still selected after E87N purge:" >&2
  echo "$leftover" >&2
  exit 1
fi

echo "E87N Wi-Fi packages force-disabled in $CFG"
