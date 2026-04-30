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

# 替换 LAN 口默认 IP (192.168.1.1 -> 10.0.0.1)
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 替换其他接口的递增网段 (192.168.$((...)) -> 10.0.$((...)))
sed -i 's/192.168.\$((addr_offset++))/10.0.\$((addr_offset++))/g' package/base-files/files/bin/config_generate

# 自动查找 DTS 文件（防止路径变动）
DTS_FILE=$(find target/linux/mediatek/ -name "mt7986a-xiaomi-redmi-router-ax6000.dts")
# 修改 Flash 分区为 512MB 布局 (UBI 分区扩容)
sed -i 's/reg = <0x600000 0x6e00000>/reg = <0x600000 0x1ea00000>/' $DTS_FILE
# 修改内存定义为 1GB 
sed -i 's/reg = <0 0x40000000 0 0x20000000>/reg = <0 0x40000000 0 0x40000000>/' $DTS_FILE

# 确保高并发参数写入系统配置
sed -i '/customized system write here/a echo "net.netfilter.nf_conntrack_max=65535" >> /etc/sysctl.conf' package/base-files/files/etc/sysctl.conf

# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 修改upnp服务地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/10.0.0.1/g" feeds/luci/applications/luci-app-upnp/htdocs/luci-static/resources/view/upnp/upnp.js

# 删除预制软件
rm -rf feeds/luci/applications/luci-app-adguardhome
rm -rf feeds/luci/applications/luci-app-turboacc

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# 下载软件包
git_sparse_clone main https://github.com/F-57/luci-app luci-app-adguardhome airconnect luci-app-airconnect luci-app-turboacc

mv package/luci-app-turboacc feeds/luci/applications/luci-app-turboacc
rm -rf package/luci-app-turboacc

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

change_name "feeds/luci/modules/luci-base/po/zh_Hans/base.po" "Processes" "系统进程"
change_name "feeds/luci/applications/luci-app-upnp/po/zh_Hans/upnp.po" "UPnP IGD & PCP" "端口映射"
change_name "feeds/luci/applications/luci-app-turboacc/po/zh_Hans/turboacc.po" "TurboACC" "网络加速"
change_name "feeds/luci/applications/luci-app-mosdns/po/zh_Hans/mosdns.po" "MosDNS" "分流助手"
change_name "feeds/luci/applications/luci-app-nikki/po/zh_Hans/nikki.po" "Nikki" "科学上网"
change_name "feeds/luci/applications/luci-app-lucky/po/zh_Hans/lucky.po" "Lucky" "全能工具"


# 更改 Argon 主题背景
#cp -f $GITHUB_WORKSPACE/images/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# 集成软件 预置编译选项 (写入 .config)
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-nikki=y
CONFIG_PACKAGE_luci-app-mosdns=y
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_luci-app-lucky=y
CONFIG_PACKAGE_luci-app-airconnect=y
EOF
