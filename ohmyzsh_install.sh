#!/bin/bash
#本脚本用于自动化安装oh my zsh
_green() {
    printf '\033[1;31;32m'
    printf -- "%b" "$1"
    printf '\033[0m'
}

_red() {
    printf '\033[1;31;31m'
    printf -- "%b" "$1"
    printf '\033[0m'
}

_yellow() {
    printf '\033[1;31;33m'
    printf -- "%b" "$1"
    printf '\033[0m'
}

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
fi

#copied & modified from atrandys trojan scripts
#copy from 秋水逸冰 ss scripts
if [[ -f /etc/redhat-release ]]; then
  release="centos"
  systemPackage="yum"
elif cat /etc/issue | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
elif cat /proc/version | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
fi


#安装zsh和git
if [ ${systemPackage} == "yum" ]; then
    ${sudoCmd} ${systemPackage} install zsh git -y -q
else
    ${sudoCmd} ${systemPackage} install zsh git -y -qq
fi

#安装oh my zsh，使用--unattended参数在安装过程中不切换默认shell且不启动zsh，目的是为了安装完ohmyzsh后能继续执行下面的命令。
sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended

#安装zsh插件
${sudoCmd} git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
${sudoCmd} git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

#修改.zshrc配置文件
${sudoCmd} sed -i '/^ZSH_THEME=".*"/s/".*"/"ys"/g' ~/.zshrc
${sudoCmd} sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

#切换默认shell到zsh
${sudoCmd} chsh -s $(which zsh)

_green 'Configure oh my zsh...done.\n'

#启动zsh
${sudoCmd} exec zsh -l
