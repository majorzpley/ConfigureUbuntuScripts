#!/bin/bash
# Date:        2025/02/20
# Author:      majorzpley
# Author:      Wong
# Email:       wyx1214844230@outlook.com
# Website:     
# Function:    Configuring the Ubuntu host environment.
# Notes:       Currently only supports Ubuntu20、16、18
# -------------------------------------------------------------------------------
#
# Description:
#1.Check env.
#  1.1 check network
#  1.2 check use root
#  1.3 check set name
#2.Install common software and configuration.
#  2.1 configure vim
#  2.2 configure tftp
#  2.3 configure nfs
#  2.4 configure samba
#3.Install system tool for Linux or Android
# -------------------------------------------------------------------------------
# log 目前仅仅在100ask imx6ull pro上测试过
# -------------------------------------------------------------------------------
#define echo print color.
RED_COLOR='\E[1;31m'
PINK_COLOR='\E[1;35m'
YELOW_COLOR='\E[1;33m'
BLUE_COLOR='\E[1;34m'
GREEN_COLOR='\E[1;32m'
END_COLOR='\E[0m'
PLAIN='\033[0m'
#Set linux host user name.
user_name=majorzpley
# Check network.
check_network() {
    ping -c 1 www.baidu.com > /dev/null 2>&1
    if [ $? -eq 0 ];then
        echo -e "${BLUE_COLOR}Network OK.${END_COLOR}"
    else
        echo -e "${RED_COLOR}Network failure!${END_COLOR}"
        exit 1
    fi
}
# Check user must root.
check_root() {
    if [ $(id -u) != "0" ]; then
        echo -e "${RED_COLOR}Error: This script must be run as root!${END_COLOR}"
        exit 1
    fi
}
# Check set linux host user name.
check_user_name() {
    cat /etc/passwd|grep $user_name
    if [ $? -eq 0 ];then
        echo -e "${BLUE_COLOR}Check the set user name OK.${END_COLOR}"
        echo -e "12345wyx\n12345wyx" | sudo passwd root
    else
    	sudo   useradd -m $user_name   -G root -p 12345wyx
		echo -e "12345wyx\n12345wyx" | sudo passwd $user_name
		sudo sh -c "echo \"$user_name ALL=(ALL:ALL) NOPASSWD:ALL\" >> /etc/sudoers"
        echo -e "${RED_COLOR}Add majorzpley user !${END_COLOR}"
    fi
}
# 获取 Linux 主机发行版的代号并传递给调用者
get_host_type() {
    local  __host_type=$1  # 获取第一个参数并赋值给 __host_type 变量
    local  the_host=`lsb_release -a 2>/dev/null | grep Codename: | awk {'print $2'}`  # 使用 lsb_release 命令获取发行版代号
    eval $__host_type="'$the_host'"  # 将发行版代号赋值给传入的变量
}
# 检查操作结果
check_status() {
    ret=$?  # 获取上一个命令的返回值并赋值给变量 ret
    if [ "$ret" -ne "0" ]; then  # 如果 ret 不等于 0，表示上一个命令执行失败
        echo -e "${RED_COLOR}Failed setup, aborting..${END_COLOR}"  # 输出错误信息
        exit 1  # 退出脚本，返回状态码 1
    fi
}
#Select menu
menu() {
cat <<EOF
`echo -e "\E[1;33mPlease select the host use:\E[0m"`
`echo -e "\E[1;33m    1. Configuring for Harmony OS development \E[0m"`
`echo -e "\E[1;33m    2. Configuring for Linux development\E[0m"`
`echo -e "\E[1;33m    3. Configuring for Android development\E[0m"`
`echo -e "\E[1;33m    4. Quit\E[0m"`
EOF
}
# Set Ubuntu Source list address for USTC
SetUbuntuSourceList(){
        get_host_type host_release
        echo -e "${BLUE_COLOR}Host release: ${host_release}${END_COLOR}"
        if [[ -f /etc/apt/sources.list.bak ]]; then
                echo -e " ${GREEN_COLOR}sources.list.bak exists${PINK_COLOR}"
        else
                mv /etc/apt/sources.list{,.bak}
        fi
        [ -f /etc/apt/sources.list ] && rm /etc/apt/sources.list
        echo "deb https://mirrors.ustc.edu.cn/ubuntu/ focal main restricted universe multiverse" >>/etc/apt/sources.list
        echo "deb https://mirrors.ustc.edu.cn/ubuntu/ focal-security main restricted universe multiverse" >>/etc/apt/sources.list
        echo "deb https://mirrors.ustc.edu.cn/ubuntu/ focal-updates main restricted universe multiverse" >>/etc/apt/sources.list
        echo "deb https://mirrors.ustc.edu.cn/ubuntu/ focal-backports main restricted universe multiverse" >>/etc/apt/sources.list
        echo "deb https://mirrors.ustc.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse" >>/etc/apt/sources.list
        echo "deb-src https://mirrors.ustc.edu.cn/ubuntu/ focal main restricted universe multiverse" >>/etc/apt/sources.list
        echo "deb-src https://mirrors.ustc.edu.cn/ubuntu/ focal-security main restricted universe multiverse" >>/etc/apt/sources.list
        echo "deb-src https://mirrors.ustc.edu.cn/ubuntu/ focal-updates main restricted universe multiverse" >>/etc/apt/sources.list
        echo "deb-src https://mirrors.ustc.edu.cn/ubuntu/ focal-backports main restricted universe multiverse" >>/etc/apt/sources.list
        echo "deb-src https://mirrors.ustc.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse" >>/etc/apt/sources.list

        # 根据 host_release 进行条件判断并替换 sources.list 中的内容
        if [ "$host_release" == "xenial" ]; then
            sed -i 's/focal/xenial/g' /etc/apt/sources.list
        elif [ "$host_release" == "bionic" ]; then
            sed -i 's/focal/bionic/g' /etc/apt/sources.list
        fi
        sleep 1
        apt-get update
}
# Configure vim from gitee
vim_configure(){
    git clone --depth=1 https://gitee.com/majorzpleyWong/vimrc.git /home/$user_name/.vim_runtime
    touch /home/$user_name/.vim_runtime/my_configs.vim
    echo "let g:go_version_warning = 0" > /home/$user_name/.vim_runtime/my_configs.vim

    chown -R $user_name /home/$user_name/.vim_runtime
    chmod u+x /home/$user_name/.vim_runtime/install_awesome_vimrc.sh
    su - $user_name -s /home/$user_name/.vim_runtime/install_awesome_vimrc.sh
}
# Configure tftp 
tftp_configure(){
    tftp_file=/home/$user_name/tftpboot  # 定义 TFTP 服务器的根目录路径
    if [ ! -d "$tftp_file" ];then  # 检查目录是否存在
        mkdir -p -m 777 $tftp_file  # 如果目录不存在，则创建目录并设置权限为 777
    fi
    grep "/home/$user_name/tftpboot" /etc/default/tftpd-hpa 1>/dev/null  # 检查配置文件中是否已经包含 TFTP 目录配置
    if [ $? -ne 0 ];then  # 如果配置文件中没有包含 TFTP 目录配置
        sed  -i '$a\TFTP_DIRECTORY="/home/'"$user_name"'/tftpboot"' /etc/default/tftpd-hpa  # 添加 TFTP 目录配置
        sed  -i '$a\TFTP_OPTIONS="-l -c -s"' /etc/default/tftpd-hpa  # 添加 TFTP 选项配置
    fi
    service tftpd-hpa restart  # 重启 TFTP 服务
}
# Configure nfs.
nfs_configure() {
    nfs_file=/home/$user_name/nfs_rootfs  # 定义 NFS 服务器的根目录路径

    if [ ! -d "$nfs_file" ];then  # 检查目录是否存在
        mkdir -p -m 777 $nfs_file  # 如果目录不存在，则创建目录并设置权限为 777
    fi
    grep "/home/$user_name/" /etc/exports 1>/dev/null  # 检查配置文件中是否已经包含 NFS 目录配置
    if [ $? -ne 0 ];then  # 如果配置文件中没有包含 NFS 目录配置
        # 添加 NFS 目录配置
        sed -i '$a\/home/'"$user_name"'/  *(rw,nohide,insecure,no_subtree_check,async,no_root_squash)' /etc/exports   
    fi
    service nfs-kernel-server restart  # 重启 NFS 服务
}
# Configure samba.
samba_configure() {
    local back_file=/etc/samba/smb.conf.bakup  # 定义备份文件路径
    if [ ! -e "$back_file" ];then  # 检查备份文件是否存在
        cp /etc/samba/smb.conf $back_file  # 如果备份文件不存在，则备份原始配置文件
    fi
    check_status  # 检查上一个命令的执行结果

    grep "share_directory" /etc/samba/smb.conf 1>/dev/null  # 检查配置文件中是否已经包含共享目录配置
    if [ $? -ne 0 ];then  # 如果配置文件中没有包含共享目录配置
        # 添加共享目录配置
        sed -i \
        '$a[share_directory]\n\
        path = \/home\/'"$user_name"'\n\
        available = yes\n\
        public = yes\n\
        guest ok = yes\n\
        read only = no\n\
        writeable = yes\n' /etc/samba/smb.conf
    fi

    service smbd restart  # 重启 Samba 服务
    check_status  # 检查重启服务的结果
}
# Execute an action.
FA_DoExec() {
    echo -e "${BLUE_COLOR}==> Executing: '${@}'.${END_COLOR}"
    eval $@ || exit $?
}
# Install common software and configuration
install_common_software(){
    apt-get update
    check_status

    # local install_software_list=("ssh" "git" "vim" "tftp" "nfs" "samba")
    local install_software_list=("ssh" "git" "vim" "tftp" "nfs")
    echo -e "${BLUE_COLOR}install_software_list: ${install_software_list[*]}.${END_COLOR}"

    #install ssh
    if (echo "${install_software_list[@]}" | grep -wq "ssh");then
        apt-get -y install openssh-server && echo -e "${BLUE_COLOR}ssh install completed.${END_COLOR}"
    fi
    #install git
    if (echo "${install_software_list[@]}" | grep -wq "git");then
        apt-get -y install git && echo -e "${BLUE_COLOR}git install completed.${END_COLOR}"
    fi
    #install and configure vim
    if (echo "${install_software_list[@]}" | grep -wq "vim");then
        apt-get -y install vim && vim_configure && echo -e "${BLUE_COLOR}vim install and configure completed.${END_COLOR}"
    fi
    #install and configure tftp
    if (echo "${install_software_list[@]}" | grep -wq "tftp");then
        apt-get -y install tftp-hpa tftpd-hpa && tftp_configure && echo -e "${BLUE_COLOR}tftp install completed.${END_COLOR}"
    fi
    #install and configure nfs
    if (echo "${install_software_list[@]}" | grep -wq "nfs");then
        apt-get -y install nfs-kernel-server && nfs_configure && echo -e "${BLUE_COLOR}nfs install completed.${END_COLOR}"
    fi
    #install and configure samba
    # if (echo "${install_software_list[@]}" | grep -wq "samba");then
    #     apt-get -y install samba && samba_configure && echo -e "${BLUE_COLOR}samba install completed.${END_COLOR}"
    # fi
}
# 安装自定义软件
install_user_software() {
	wget  https://weidongshan.coding.net/p/DevelopmentEnvConf/d/DevelopmentEnvConf/git/raw/master/mkimage.stm32
	chmod +x  mkimage.stm32
	sudo mv  mkimage.stm32 /usr/bin/
}
# Install software for linux
install_linux_software(){
    local ubuntu16=("xenial")
    local ubuntu18=("bionic")
    local ubuntu20=("focal")

    get_host_type host_release

    if [ "$host_release" = "$ubuntu16" ]
    then
        FA_DoExec apt-get install mtd-utils curl gcc make git vim python net-tools openssh-server \
        python-dev build-essential subversion \
        libncurses5-dev zlib1g-dev gawk gcc-multilib flex git-core gettext  \
        gfortran libssl-dev libpcre3-dev xlibmesa-glu-dev libglew1.5-dev \
        libftgl-dev libmysqlclient-dev libfftw3-dev libcfitsio-dev graphviz-dev \
        libavahi-compat-libdnssd-dev libldap2-dev  libxml2-dev p7zip-full \
        libkrb5-dev libgsl0-dev  u-boot-tools lzop bzr device-tree-compiler android-tools-mkbootimg -y
    else
        if [ "$host_release" = "$ubuntu18" ]
        then
            echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections
            FA_DoExec apt-get install curl mtd-utils  gcc make git vim python net-tools openssh-server \
            python-dev build-essential subversion \
            libncurses5-dev zlib1g-dev gawk gcc-multilib flex git-core gettext  \
            gfortran libssl-dev libpcre3-dev xlibmesa-glu-dev libglew1.5-dev \
            libftgl-dev libmysqlclient-dev libfftw3-dev libcfitsio-dev graphviz-dev \
            libavahi-compat-libdnssd-dev libldap2-dev  libxml2-dev p7zip-full bzr  \
            libkrb5-dev libgsl0-dev  u-boot-tools lzop -y
        else
            if [ "$host_release" = "$ubuntu20" ]
            then
                # echo "This Ubuntu version is 20.04"
                echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections
                FA_DoExec apt-get install curl mtd-utils  gcc make git vim python net-tools openssh-server \
                python-dev build-essential subversion \
                libncurses5-dev zlib1g-dev gawk gcc-multilib flex git-core gettext  \
                gfortran libssl-dev libpcre3-dev xlibmesa-glu-dev libglew1.5-dev \
                libftgl-dev libmysqlclient-dev libfftw3-dev libcfitsio-dev graphviz-dev \
                libavahi-compat-libdnssd-dev libldap2-dev  libxml2-dev p7zip-full bzr  \
                libkrb5-dev libgsl0-dev  u-boot-tools lzop liblz4-tool expect patchelf chrpath  \
                texinfo diffstat binfmt-support qemu-user-static live-build bison fakeroot cmake    \
                gcc-multilib g++-multilib unzip device-tree-compiler python3-pip    \
                python3-pyelftools dpkg-dev -y
            else
                echo "This Ubuntu version is not supported"
                exit 0
            fi
        fi
    fi


}

check_network
check_root
check_user_name
menu
while true
do
    read -p "Please input ur choice:" ch
    case $ch in
        1)
            ;;
        2)
            SetUbuntuSourceList
            install_common_software
            install_linux_software
            install_user_software
            echo -e "${GREEN_COLOR}===================================================${END_COLOR}"
            echo -e "${GREEN_COLOR}==  Configuring for Linux development complete!  ==${END_COLOR}"
            echo -e "${GREEN_COLOR}===================================================${END_COLOR}"
            echo -e "${BLUE_COLOR}TFTP  PATH: $tftp_file ${END_COLOR}"
            echo -e "${BLUE_COLOR}NFS   PATH: $nfs_file ${END_COLOR}"
            echo -e "${BLUE_COLOR}SAMBA PATH: /home/majorzpley/ ${END_COLOR}"
            su $user_name
            ;;
        3)
            ;;
        4)
            break
            exit 0
            ;;
        *)
            clear
            echo "Sorry, Wrong Selection"
            exit 0
            ;;
    esac
done

exit 0