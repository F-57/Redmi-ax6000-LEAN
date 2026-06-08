#!/bin/bash

# IP 网段及服务地址配置
CFG_FILE="./package/base-files/files/bin/config_generate"
sed -i 's/192.168.1.1/10.0.0.1/g' $CFG_FILE
sed -i 's/192.168.\$((addr_offset++))/10.0.\$((addr_offset++))/g' $CFG_FILE

UPNP_JS="feeds/luci/applications/luci-app-upnp/htdocs/luci-static/resources/view/upnp/upnp.js"
sed -i "s/192\.168\.[0-9]*\.[0-9]*/10.0.0.1/g" $UPNP_JS

# 无线无线 WiFi 基础配置
WIFI_FILE="./package/kernel/mac80211/files/lib/wifi/mac80211.sh"
sed -i 's/country="US"/country="CN"/g' $WIFI_FILE
sed -i 's/ssid="LEDE"/ssid="Ax6000"/g' $WIFI_FILE

# 红米 AX6000 硬件设备树补丁 (512MB 闪存 / 1GB 内存)
DTS_FILE=$(find target/linux/mediatek/ -name "mt7986a-xiaomi-redmi-router-ax6000.dts")
sed -i 's/reg = <0x600000 0x6e00000>/reg = <0x600000 0x1ea00000>/' $DTS_FILE
sed -i 's/reg = <0 0x40000000 0 0x20000000>/reg = <0 0x40000000 0 0x40000000>/' $DTS_FILE

# 内核网络内核参数追加
SYSCTL_FILE="package/base-files/files/etc/sysctl.conf"
sed -i '$a net.netfilter.nf_conntrack_max=163840' $SYSCTL_FILE
sed -i '$a net.netfilter.nf_conntrack_buckets=40960' $SYSCTL_FILE

# 精准替换 zzz-default-settings 里的 Lean 默认密码密文为 cw010203
cp -f $GITHUB_WORKSPACE/diy/zzz-default-settings package/lean/default-settings/files/zzz-default-settings
if [ $? -eq 0 ]; then
    echo "成功：zzz-default-settings 替换成功。"
else
    echo "失败：zzz-default-settings 替换失败！"
    exit 1
fi

# 删除 TurboACC 前端界面中的“高性能博通”选项
TURBOACC_JS="feeds/luci/applications/luci-app-turboacc/htdocs/luci-static/resources/view/turboacc.js"
if [ -f "$TURBOACC_JS" ]; then
    sed -i "/Boardcom Fullcone NAT1/d" "$TURBOACC_JS"
    echo "TurboACC: 已移除前端博通高性能选项"
fi

# 删除预制软件
rm -rf feeds/luci/applications/luci-app-adguardhome

# 终极反向洗白：用官方纯正 luci-mod-status 彻底强制覆盖本地所有包
echo "=== [INFO] 开始执行官方 luci-mod-status 包反向强制覆盖 ==="
rm -rf feeds/luci/modules/luci-mod-status
rm -rf package/feeds/luci/luci-mod-status
find . -type d -name "luci-mod-status" -exec rm -rf {} \; 2>/dev/null

# 我们换用最稳妥的官方完整 feeds 库拉取法（直接现场去官方源抓取最干净的单包覆盖它）：
rm -rf feeds/luci/modules/luci-mod-status
git clone --depth=1 https://github.com/openwrt/luci /tmp/official888_luci
if [ -d "/tmp/official_luci/modules/luci-mod-status" ]; then
    cp -rf /tmp/official888_luci/modules/luci-mod-status feeds/luci/modules/
    echo "成功：已成功从官方源抓取最纯正的 luci-mod-status 组件！"
else
    echo "错误：抓取官方源失败，请检查网络！"
fi
rm -rf /tmp/official888_luci

# 3. 强行重置系统软链接，让 OpenWrt 的编译主引擎重新认识这个刚刚洗白回来的官方包
./scripts/feeds install luci-mod-status

# 4. 彻底擦除常驻缓存
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache 2>/dev/null
echo "成功：已强制清空 LuCI 路由所有常驻缓存。"

echo "=== [INFO] 官方包反向强制覆盖流程执行完毕 ==="

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
git_sparse_clone main https://github.com/F-57/luci-app luci-app-adguardhome airconnect luci-app-airconnect
git clone --depth 1 https://github.com/eamonxg/luci-theme-shadcn package/luci-theme-shadcn

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
change_name "feeds/luci/applications/luci-app-mosdns/po/zh_Hans/mosdns.po" "MosDNS" "域名分流"
change_name "feeds/luci/applications/luci-app-openclash/po/zh-cn/openclash.zh-cn.po" "OpenClash" "科学上网"
change_name "feeds/luci/applications/luci-app-lucky/po/zh_Hans/lucky.po" "Lucky" "网络工具"
change_name "feeds/luci/applications/luci-app-cloudflared/po/zh_Hans/cloudflared.po" "Cloudflare Zero Trust Tunnel" "全球隧道"

# 移动 Cloudflare 菜单从 VPN 到 Services
CF_MENU="feeds/luci/applications/luci-app-cloudflared/root/usr/share/luci/menu.d/luci-app-cloudflared.json"
if [ -f "$CF_MENU" ]; then
    sed -i 's/admin\/vpn\/cloudflared/admin\/services\/cloudflared/g' "$CF_MENU"
    echo "已将 Cloudflared 菜单移动至服务菜单下"
fi

# 更改 Argon 主题背景
#cp -f $GITHUB_WORKSPACE/images/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# LED RGB灯效
sed -i 's/\r$//' ./files/etc/config/my_led.lua
chmod +x ./files/etc/config/my_led.lua
mkdir -p ./files/etc/
if [ -f "package/base-files/files/etc/rc.local" ]; then
    cp package/base-files/files/etc/rc.local ./files/etc/rc.local
else
    echo -e "#!/bin/sh -e\n\nexit 0" > ./files/etc/rc.local
fi

sed -i '/exit 0/i \/etc/config/my_led.lua > /tmp/my_led.log 2>&1 &' ./files/etc/rc.local
chmod +x ./files/etc/rc.local

# 集成软件 预置编译选项 (写入 .config)
cat >> .config <<EOF
CONFIG_PACKAGE_luci-theme-shadcn=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-mosdns=y
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_luci-app-lucky=y
CONFIG_PACKAGE_luci-app-airconnect=y
CONFIG_PACKAGE_luci-app-cloudflared=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-ttyd=y
EOF
