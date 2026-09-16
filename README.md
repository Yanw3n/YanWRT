# YanWRT

Fork of [davidtall/DaeWRT-CI](https://github.com/davidtall/DaeWRT-CI)，**仅适配 EdgePi / Hiveton E87N (MT7987A)**。

## 包合并

| 来源 | 内容 |
|------|------|
| DaeWRT-CI | `package/dae`、`package/luci-app-dae`、`package/v2ray-geodata` |
| Yanw3n/imagebuilder | `package/e87n` 风扇控制 + E87N DTS/补丁 |

## 配置

`Config/` 下**只保留** `E87N.txt`（已合并原 GENERAL 必要项）。

## 编译

GitHub Actions → **MEDIATEK-E87N** → Run workflow  

- 源码：`immortalwrt/immortalwrt` @ `openwrt-25.12`  
- 默认 LAN：`172.16.25.1`

本地：`./diy.sh`（默认 `WRT_CONFIG=E87N`）
