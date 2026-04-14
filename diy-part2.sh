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

# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 修改upnp服务地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/10.0.0.1/g" feeds/luci/applications/applications/luci-app-upnp/htdocs/luci-static/resources/view/upnp/upnp.js

# 删除预制软件
rm -rf feeds/luci/applications/luci-app-vlmcsd
rm -rf feeds/luci/applications/luci-app-vsftpd
rm -rf feeds/luci/applications/luci-app-accesscontrol
rm -rf feeds/luci/applications/luci-app-nlbwmon
rm -rf feeds/luci/applications/luci-app-wol
rm -rf feeds/luci/applications/luci-app-ddns
rm -rf feeds/luci/applications/luci-app-arpbind
rm -rf package/lean/ddns-scripts_aliyun
rm -rf package/lean/ddns-scripts_dnspod
rm -rf feeds/luci/applications/luci-app-turboacc

rm -rf feeds/luci/applications/luci-app-adguardhome
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/net/mosdns
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/lang/golang

# 下载软件包
git clone --depth=1 https://github.com/F-57/luci-app-adguardhome package/luci-app-adguardhome
git clone --depth=1 https://github.com/sbwml/luci-app-airconnect package/luci-app-airconnect
git clone --depth=1 https://github.com/sirpdboy/luci-app-lucky package/luci-app-lucky
git clone --depth=1 https://github.com/derisamedia/luci-theme-alpha-reborn package/luci-theme-alpha-reborn
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone --depth=1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# 更改菜单名字 定义一个快捷函数：参数1是文件路径，参数2是原始文字，参数3是目标文字
change_name() {
    local file=$1
    local id=$2
    local str=$3
    if [ -f "$file" ]; then
        # 匹配 msgid 后的下一行 msgstr 并进行替换
        sed -i "/msgid \"$id\"/{n;s/msgstr \".*\"/msgstr \"$str\"/}" "$file"
        echo "已修改 $id 为 $str"
    else
        echo "跳过：未找到文件 $file"
    fi
}

change_name "package/mosdns/luci-app-mosdns/po/zh_Hans/mosdns.po" "MosDNS" "转发分流"
change_name "feeds/luci/applications/luci-app-upnp/po/zh_Hans/upnp.po" "UPnP IGD & PCP" "端口转发"
change_name "package/lucky/luci-app-lucky/po/zh_Hans/lucky.po" "Lucky" "大吉大利"
change_name "feeds/luci/applications/luci-app-turboacc/po/zh_Hans/turboacc.po " "TurboACC" "网络加速"

# 集成软件 预置编译选项 (写入 .config)
cat >> .config <<EOF
CONFIG_PACKAGE_luci-theme-alpha-reborn=y
CONFIG_PACKAGE_luci-app-mosdns=y
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_luci-app-lucky=y
CONFIG_PACKAGE_luci-app-airconnect=y
CONFIG_PACKAGE_luci-app-ttyd=y
EOF
