#!/bin/bash

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

md5sum result.csv | grep -q 50be6679e544f9cc85f1db223d5544ed && yellow "您正在使用本项目预置的warp节点，建议您自行进行优选IP并替换左侧的files/result.csv文件。"

rm -f wgcf-account.toml wgcf-profile.conf
green "请稍等..."
chmod +x ./wgcf
echo | ./wgcf register >/dev/null 2>&1
chmod +x wgcf-account.toml 

yellow "获取CloudFlare WARP账号密钥信息方法: "
green "电脑: 下载并安装CloudFlare WARP→设置→偏好设置→账户→复制密钥到脚本中"
green "手机: 下载并安装1.1.1.1 APP→菜单→账户→复制密钥到脚本中"
echo ""
yellow "重要：请确保手机或电脑的1.1.1.1 APP的账户状态为WARP+！"
read -rp "输入WARP账户许可证密钥 (26个字符):" warpkey
until [[ -z $warpkey || $warpkey =~ ^[A-Z0-9a-z]{8}-[A-Z0-9a-z]{8}-[A-Z0-9a-z]{8}$ ]]; do
  red "WARP账户许可证密钥格式输入错误，请重新输入！"
  read -rp "输入WARP账户许可证密钥 (26个字符): " warpkey
done
if [[ -n $warpkey ]]; then
  sed -i "s/license_key.*/license_key = \"$warpkey\"/g" wgcf-account.toml
  read -rp "请输入自定义设备名，如未输入则使用默认随机设备名: " devicename
  green "注册WARP+账户中, 如下方显示:400 Bad Request, 则使用WARP免费版账户"
  if [[ -n $devicename ]]; then
    wgcf update --name $(echo $devicename | sed s/[[:space:]]/_/g) > /etc/wireguard/info.log 2>&1
  else
    wgcf update
  fi
else
  red "未输入WARP账户许可证密钥，将使用WARP免费账户"
fi

set -e
./wgcf generate

set +e
# use grep to find the license key
license_key=$(egrep -o "license_key = '(.+)'" wgcf-account.toml | cut -d "'" -f 2)
if [[ -z $license_key ]]; then
    license_key="unknown"
fi
# replace - with _ in license key
license_key=${license_key//-/_}
set -e

output_filename="surfboard_warp_${license_key}.conf"
python3 generate_surfboard_config.py wgcf-profile.conf > ../$output_filename

rm -f wgcf-account.toml wgcf-profile.conf
green 生成完成，文件名：$output_filename
green 左侧右键点击${output_filename}，再点击Download即可下载

sub_link=$(curl -H "Max-Downloads: 1145141919810" -H "Max-Days: 105850" --upload-file ../$output_filename https://transfer.sh/$output_filename)
echo 订阅链接（14天内有效，请尽快下载）：$sub_link

echo "$sub_link" | qrencode -t ansiutf8 

red 警告：公开的replit库里的内容可以被任何人看到！
red 如果你使用了公开的replit库（replit免费账号），那么请你下载完后删除配置文件，否则你的配置文件将会被盗用！
red 如果你使用了公开的replit库（replit免费账号），那么请你下载完后删除配置文件，否则你的配置文件将会被盗用！
red 如果你使用了公开的replit库（replit免费账号），那么请你下载完后删除配置文件，否则你的配置文件将会被盗用！