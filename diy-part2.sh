#!/bin/bash
#
# Copyright (c) 2019-2023 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#


# 1. 替换 LAN 口默认 IP (192.168.1.1 -> 10.0.0.1)
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 2. 替换其他接口的递增网段 (192.168.$((...)) -> 10.0.$((...)))
sed -i 's/192.168.\$((addr_offset++))/10.0.\$((addr_offset++))/g' package/base-files/files/bin/config_generate

# 512布局
sed -i 's/reg = <0x600000 0x6e00000>/reg = <0x600000 0x1ea00000>/' target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000.dts

# 删除软件
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/luci/applications/luci-app-vlmcsd
rm -rf feeds/luci/applications/luci-app-vsftpd
rm -rf feeds/luci/applications/luci-app-accesscontrol
rm -rf feeds/luci/applications/luci-app-nlbwmon
rm -rf feeds/luci/applications/luci-app-wol
rm -rf feeds/luci/applications/luci-app-ddns
rm -rf feeds/luci/applications/luci-app-arpbind
rm -rf package/lean/ddns-scripts_aliyun
rm -rf package/lean/ddns-scripts_dnspod

# 改菜单名字
sed -i '/msgid "TurboACC"/{n;s/msgstr ".*"/msgstr "网络加速"/}' feeds/luci/applications/luci-app-turboacc/po/zh_Hans/turboacc.po

# 下载软件包
git clone https://github.com/sirpdboy/luci-app-wizard package/luci-app-wizard


echo "CONFIG_PACKAGE_luci-theme-argon=y" >> .config
echo "CONFIG_PACKAGE_luci-app-wizard=y" >> .config
