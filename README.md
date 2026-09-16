# YanWRT

Fork of [davidtall/DaeWRT-CI](https://github.com/davidtall/DaeWRT-CI)，面向 **EdgePi / Hiveton E87N (MT7987A)** 的云编译固件。

## 相对上游的主要改动

| 来源 | 内容 |
|------|------|
| **DaeWRT-CI** | `package/dae`、`package/luci-app-dae`、`package/v2ray-geodata`，以及 CI / GENERAL 中的 dae 相关选项 |
| **Yanw3n/imagebuilder** | `package/e87n` 风扇控制（`fancontrol` / `luci-app-fancontrol` / 中文翻译）、E87N 设备补丁与 DTS overlay |

## E87N 构建

GitHub Actions → **MEDIATEK-E87N**（`workflow_dispatch`）

- 源码：`immortalwrt/immortalwrt` @ `openwrt-25.12`
- 配置：`Config/E87N.txt` + `Config/GENERAL.txt`
- 默认 LAN IP：`172.16.25.1`

本地可参考上游 `diy.sh`，将 `WRT_CONFIG` 设为 `E87N`。

## 目录

- `Config/` — 机型与通用配置（含 `E87N.txt`）
- `Scripts/` — 插件拉取 / Handles（含 E87N overlay+patch）
- `package/dae`、`package/luci-app-dae`、`package/v2ray-geodata` — DaeWRT 代理栈
- `package/e87n/` — E87N 风扇 LuCI/守护进程
- `device/edgepi-e87n/source-overlay/` — DTS 等 overlay
- `patches/e87n/` — ImmortalWrt filogic 设备补丁

## 上游说明

本仓库基于 DaeWRT-CI（再上游为 VIKINGYFY/OpenWRT-CI），开启内核 eBPF，支持 DAE 内核级透明代理。
