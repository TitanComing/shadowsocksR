#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  CentOS 6,7, Debian, Ubuntu                  #
#   Description: One click Install ShadowsocksR Server;           #
#                Tt is a practice                                 #
#   Author: noName                                                #
#   Thanks:Author: 91yun <https://twitter.com/91yun>              #
#	  Thanks: Toyo + AlphaBrock                                     #
#   Thanks:Teddysun <i@teddysun.com>                              #
#   Thanks: @breakwa11 <https://twitter.com/breakwa11>            #
#   Time:  2017.1.13                                              #
#=================================================================

clear
echo
echo "#############################################################"
echo "# One click Install ShadowsocksR Server                     #"
echo "# Author: noName                                            #"
echo "# Thanks:Author: 91yun <https://twitter.com/91yun>          #"
echo "#	Thanks: Toyo + AlphaBrock                                 #"
echo "# Thanks:Teddysun <i@teddysun.com>                          #"
echo "# Thanks: @breakwa11 <https://twitter.com/breakwa11>        #"
echo "# Date:  2017.1.13                                          #"
echo "# 自用脚本，无长期维护计划，有问题请移步以上感谢中所提到的项目   #"
echo "#############################################################"
echo

#Current folder
cur_dir=`pwd`

# Make sure only root can run our script
rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error: This script must be run as root!" 1>&2
       exit 1
    fi
}

# Disable selinux
disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

#Check system
check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ ${checkType} == "sysRelease" ]]; then
        if [ "$value" == "$release" ]; then
            return 0
        else
            return 1
        fi
    elif [[ ${checkType} == "packageManager" ]]; then
        if [ "$value" == "$systemPackage" ]; then
            return 0
        else
            return 1
        fi
    fi
}

# Get version
getversion(){
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

# CentOS version
centosversion(){
    if check_sys sysRelease centos; then
        local code=$1
        local version="$(getversion)"
        local main_ver=${version%%.*}
        if [ "$main_ver" == "$code" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Get public IP address
get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com ) #公网IP
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip ) #外网IP
    [ ! -z ${IP} ] && echo ${IP} || echo
}

# Pre-installation settings
pre_install(){
    if check_sys packageManager yum || check_sys packageManager apt; then
        # Not support CentOS 5
        if centosversion 5; then
            echo "Error: Not supported CentOS 5, please change to CentOS 6+/Debian 7+/Ubuntu 12+ and try again."
            exit 1
        fi
    else
        echo "Error: Your OS is not supported. please change OS to CentOS/Debian/Ubuntu and try again."
        exit 1
    fi
    # Set ShadowsocksR config password
    echo "Please input password for ShadowsocksR:"
    read -p "(Default password: noName):" shadowsockspwd
    [ -z "${shadowsockspwd}" ] && shadowsockspwd="noName"
    echo
    echo "---------------------------"
    echo "password = ${shadowsockspwd}"
    echo "---------------------------"
    echo
    # Set ShadowsocksR config port
    while true
    do
    echo -e "Please input port for ShadowsocksR [1-65535]:"
    read -p "(Default port: 8989):" shadowsocksport
    [ -z "${shadowsocksport}" ] && shadowsocksport="8989"
    expr ${shadowsocksport} + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${shadowsocksport} -ge 1 ] && [ ${shadowsocksport} -le 65535 ]; then
            echo
            echo "---------------------------"
            echo "port = ${shadowsocksport}"
            echo "---------------------------"
            echo
            break
        else
            echo "Input error, please input correct number"
        fi
    else
        echo "Input error, please input correct number"
    fi
    done
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    # Install necessary dependencies
    if check_sys packageManager yum; then
      yum install -y wget unzip openssl-devel gcc swig python python-devel python-setuptools autoconf libtool libevent git ntpdate
      yum install -y m2crypto automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel
      #yum install -y unzip openssl-devel gcc swig python python-devel python-setuptools autoconf libtool libevent automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel
    elif check_sys packageManager apt; then
        apt-get -y update
        apt-get -y install python python-dev python-pip python-m2crypto curl wget unzip gcc swig automake make perl cpio build-essential git ntpdate
        #apt-get -y install python python-dev python-pip python-m2crypto curl wget unzip gcc swig automake make perl cpio build-essential
    fi
    cd ${cur_dir}
}

# Download files
download_files(){
    # Download libsodium file
    if ! wget --no-check-certificate -O libsodium-1.0.11.tar.gz https://github.com/jedisct1/libsodium/releases/download/1.0.11/libsodium-1.0.11.tar.gz; then
        echo "Failed to download libsodium-1.0.11.tar.gz!"
        exit 1
    fi
    # Download ShadowsocksR file
    #if ! wget --no-check-certificate -O manyuser.zip https://github.com/shadowsocksr/shadowsocksr/archive/manyuser.zip; then  #shadowsocksR-python版本
    #    echo "Failed to download ShadowsocksR file!"
    #    exit 1
    #fi
    if ! git clone -b manyuser https://github.com/breakwa11/shadowsocks.git /usr/local/shadowsocks; then  #shadowsocksR-python版本
        echo "Failed to download ShadowsocksR file!"
        exit 1
    fi
    # Download ShadowsocksR init script
    if check_sys packageManager yum; then
        if ! wget --no-check-certificate https://raw.githubusercontent.com/TitanComing/shadowsocksR-/master/chkcofig.sh -O /etc/init.d/shadowsocks; then
            echo "Failed to download ShadowsocksR chkconfig file!"
            exit 1
        fi
    elif check_sys packageManager apt; then
        if ! wget --no-check-certificate https://raw.githubusercontent.com/TitanComing/shadowsocksR-/master/chkconfig-debain.sh -O /etc/init.d/shadowsocks; then
            echo "Failed to download ShadowsocksR chkconfig file!"
            exit 1
        fi
    fi
}

# Firewall set
firewall_set(){
    echo "firewall set start..."
    if centosversion 6; then
        /etc/init.d/iptables status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            iptables -L -n | grep -i ${shadowsocksport} > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${shadowsocksport} -j ACCEPT
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${shadowsocksport} -j ACCEPT
                /etc/init.d/iptables save
                /etc/init.d/iptables restart
            else
                echo "port ${shadowsocksport} has been set up."
            fi
        else
            echo "WARNING: iptables looks like shutdown or not installed, please manually set it if necessary."
        fi
    elif centosversion 7; then
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/tcp
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/udp
            firewall-cmd --reload
        else
            echo "Firewalld looks like not running, try to start..."
            systemctl start firewalld
            if [ $? -eq 0 ]; then
                firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/tcp
                firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/udp
                firewall-cmd --reload
            else
                echo "WARNING: Try to start firewalld failed. please enable port ${shadowsocksport} manually if necessary."
            fi
        fi
    fi
    echo "firewall set completed..."
}

# Config ShadowsocksR
config_shadowsocks(){
    cat > /etc/shadowsocks.json<<-EOF
{
    "server":"0.0.0.0",
    "server_ipv6":"::",
    "server_port":${shadowsocksport},
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "timeout":120,
    "method":"chacha20",
    "protocol":"auth_sha1_v4_compatible",
    "protocol_param":"",
    "obfs":"tls1.2_ticket_auth_compatible",
    "obfs_param":"",
    "redirect":"",
    "dns_ipv6":false,
    "fast_open":false,
    "workers":1
}
EOF
}

# Install ShadowsocksR
install_ssr(){
    # Install libsodium
    tar zxf libsodium-1.0.11.tar.gz
    cd libsodium-1.0.11
    ./configure && make && make install
    if [ $? -ne 0 ]; then
        echo "libsodium install failed!"
        install_cleanup
        exit 1
    fi
    echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf
    ldconfig
    # Install ShadowsocksR
    cd ${cur_dir}
    #unzip -q manyuser.zip
    #mv shadowsocksr-manyuser/shadowsocks /usr/local/
    if [ -f /usr/local/shadowsocks/server.py ]; then
        chmod +x /etc/init.d/shadowsocks
        if check_sys packageManager yum; then
            chkconfig --add shadowsocks
            chkconfig shadowsocks on
        elif check_sys packageManager apt; then
            update-rc.d -f shadowsocks defaults
        fi
        /etc/init.d/shadowsocks start

        clear
        echo
        echo "Congratulations, ShadowsocksR install completed!"
        echo -e "Server IP: \033[41;37m $(get_ip) \033[0m"
        echo -e "Server Port: \033[41;37m ${shadowsocksport} \033[0m"
        echo -e "Password: \033[41;37m ${shadowsockspwd} \033[0m"
        echo -e "Local IP: \033[41;37m 127.0.0.1 \033[0m"
        echo -e "Local Port: \033[41;37m 1080 \033[0m"
        echo -e "Protocol: \033[41;37m auth_sha1_v4_compatible \033[0m"
        echo -e "obfs: \033[41;37m tls1.2_ticket_auth_compatible \033[0m"
        echo -e "Encryption Method: \033[41;37m chacha20 \033[0m"
        echo
        echo "Welcome to visit:https://shadowsocks.be/9.html"
        echo "If you want to change protocol & obfs, please visit reference URL:"
        echo "https://github.com/breakwa11/shadowsocks-rss/wiki/Server-Setup"
        echo
        echo "Enjoy it!"
        echo
    else
        echo "ShadowsocksR install failed"
        install_cleanup
        exit 1
    fi
}

#change time to beijing-time
check_datetime(){
  rm -rf /etc/localtime
  ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  ntpdate 1.cn.pool.ntp.org
}

#autostart when boot
autostart_SSR(){
  if centosversion 6; then
    chmod +x /etc/rc.d/rc.sysinit
    echo -e "python /usr/local/shadowsocksr/shadowsocks/server.py -d start" >> /etc/rc.d/rc.sysinit
  elif centosversion 7;then
    chmod +x /etc/rc.d/rc.local
    echo -e "python /usr/local/shadowsocksr/shadowsocks/server.py -d start" >> /etc/rc.d/rc.local
  elif check_sys packageManager apt; then
    chmod +x /etc/rc.local
    sed -i '$d' /etc/rc.local
    echo -e "python /usr/local/shadowsocksr/shadowsocks/server.py -d start" >> /etc/rc.local
    echo -e "exit 0" >> /etc/rc.local
  fi
}

#UpdateSSR
UpdateSSR(){
	#判断是否安装ShadowsocksR
	if [ ! -e /usr/local/shadowsocks ];
	then
		echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !"
		exit 1
	fi

	#进入SS目录，更新代码，然后重启SSR
	cd /usr/local/shadowsocksr
	git pull
	python /usr/local/shadowsocksr/shadowsocks/server.py -d restart
}

# Install cleanup
install_cleanup(){
    cd ${cur_dir}
    rm -rf manyuser.zip shadowsocks-manyuser libsodium-1.0.11.tar.gz libsodium-1.0.11
}


# Uninstall ShadowsocksR
uninstall_shadowsocks(){
    printf "Are you sure uninstall ShadowsocksR? (y/n)"
    printf "\n"
    read -p "(Default: n):" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        /etc/init.d/shadowsocks status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/shadowsocks stop
        fi
        if check_sys packageManager yum; then
            chkconfig --del shadowsocks
        elif check_sys packageManager apt; then
            update-rc.d -f shadowsocks remove
        fi
        rm -f /etc/shadowsocks.json
        rm -f /etc/init.d/shadowsocks
        rm -f /var/log/shadowsocks.log
        rm -rf /usr/local/shadowsocks
        echo "ShadowsocksR uninstall success!"
    else
        echo
        echo "uninstall cancelled, nothing to do..."
        echo
    fi
}

# Install ShadowsocksR
install_shadowsocks(){
    rootness
    disable_selinux
    pre_install
    download_files
    config_shadowsocks
    install
    if check_sys packageManager yum; then
        firewall_set
    fi
    install_cleanup
}

#安装锐速
installServerSpeeder(){
	#判断是否安装锐速
	if [ -e "/serverspeeder" ];
	then
		echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 已安装 !"
		exit 1
	fi
	cd /root
	#借用91yun.rog的开心版锐速
	wget -N --no-check-certificate https://raw.githubusercontent.com/91yun/serverspeeder/master/serverspeeder-all.sh
	bash serverspeeder-all.sh
  #添加系统启动
  if check_sys packageManager yum; then
	  chmod +x /etc/rc.d/rc.sysinit
    echo -e "/serverspeeder/bin/serverSpeeder.sh start" >> /etc/rc.d/rc.sysinit
  elif check_sys packageManager apt; then
 	  chmod +x /etc/rc.local
	  sed -i '$d' /etc/rc.local
	  echo -e "/serverspeeder/bin/serverSpeeder.sh start" >> /etc/rc.local
	  echo -e "exit 0" >> /etc/rc.local
    fi
}

#查看锐速状态
StatusServerSpeeder(){
	#判断是否安装 锐速
	if [ ! -e "/serverspeeder" ];
	then
		echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !"
		exit 1
	fi
	/serverspeeder/bin/serverSpeeder.sh status
}

#停止锐速
StopServerSpeeder(){
	#判断是否安装 锐速
	if [ ! -e "/serverspeeder" ];
	then
		echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !"
		exit 1
	fi
	/serverspeeder/bin/serverSpeeder.sh stop
}

#重启锐速
RestartServerSpeeder(){
	#判断是否安装 锐速
	if [ ! -e "/serverspeeder" ];
	then
		echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !"
		exit 1
	fi
	/serverspeeder/bin/serverSpeeder.sh restart
	/serverspeeder/bin/serverSpeeder.sh status
}

#卸载锐速
UninstallServerSpeeder(){
	#判断是否安装 锐速
	if [ ! -e "/serverspeeder" ];
	then
		echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !"
		exit 1
	fi

	printf "确定要卸载 锐速(ServerSpeeder) ? (y/N)"
	printf "\n"
	read -p "(默认: n):" un1yn
	[ -z ${un1yn} ] && un1yn="n"
	if [[ ${un1yn} == [Yy] ]]; then
		rm -rf /root/serverspeeder-all.sh
	    rm -rf /root/91yunserverspeeder
	    rm -rf /root/91yunserverspeeder.tar.gz
		if check_sys packageManager yum; then
            sed -i '/\/serverspeeder\/bin\/serverSpeeder.sh start/d' /etc/rc.d/rc.sysinit
        elif check_sys packageManager apt; then
		    sed -i '/\/serverspeeder\/bin\/serverSpeeder.sh start/d' /etc/rc.local
        fi
		chattr -i /serverspeeder/etc/apx*
		/serverspeeder/bin/serverSpeeder.sh uninstall -f
		echo
		echo "锐速(ServerSpeeder) 卸载完成 !"
		echo
	else
		echo
		echo "卸载已取消..."
		echo
	fi
}

install_bbr(){
    # 不支持 CentOS 5
    if centosversion 5; then
        echo "暂不支持CentOS 5, 请更换系统为 CentOS 6+/Debian 7+/Ubuntu 14+ 后再试."
        exit 1
    fi
    # 选择安装bbr
    #if check_sys packageManager yum; then
       # wget -O- https://soft.alphabrock.cn/Linux/scripts/bbr_centos_6_7_x86_64.sh | bash
   # elif check_sys packageManager apt; then
       # wget -N --no-check-certificate https://soft.alphabrock.cn/Linux/scripts/bbr.sh && bash bbr.sh
   # fi
   wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
}

#菜单判断
echo "请输入一个数字来选择对应的选项。"
echo
echo "=================================="
echo
#安装 ShadowsocksR
echo "1. 安装 ShadowsocksR"
#卸载ShadowsocksR
echo "2. 卸载 ShadowsocksR"
#更新ShadowsocksR
echo "3. 更新 ShadowsocksR"
#设置系统时间
echo "4. 设置系统时间为北京时间"
echo
echo "=================================="
echo
echo
echo "=================================="
echo
echo -e "\033[41;37m [警告]: \033[0m 锐速和TCP-BBR只能安装其中一个"
echo "锐速采用91云的锐速开心版，TCP-BBR采用Teddysun的一键脚本"
echo
echo "=================================="
#安装锐速
echo "5. 安装 锐速(ServerSpeeder)"
#查看锐速状态
echo "6. 查看 锐速(ServerSpeeder) 状态"
#停止锐速
echo "7. 停止 锐速(ServerSpeeder)"
#重启锐速
echo "8. 重启 锐速(ServerSpeeder)"
#卸载锐速
echo "9. 卸载 锐速(ServerSpeeder)"
echo
echo "=================================="
echo
echo "10. 安装 Google TCP-BBR拥塞控制算法"
echo
echo "=================================="
echo
echo -e "\033[42;37m 【Tips】: \033[0m BBR安装完毕请执行以下操作以验证是否安装成功"
echo
echo "11. 查看 BBR 状态"
echo "=================================="
read -p "(请输入数字):" num

case "$num" in
	1)
	install_ssr
	;;
	2)
	uninstall_shadowsocks
	;;
	3)
	UpdateSSR
	;;
  4)
  check_datetime
  ;;
	5)
	installServerSpeeder
	;;
	6)
	StatusServerSpeeder
	;;
	7)
	StopServerSpeeder
	;;
	8)
	RestartServerSpeeder
	;;
	9)
	UninstallServerSpeeder
	;;
	10)
	install_bbr
	;;
	11)
	lsmod | grep bbr
	;;
	*)
	echo '请选择 1-11 的数字。'
	;;
esac

# Initialization step
#action=$1
#[ -z $1 ] && action=install
#case "$action" in
    install|uninstall)
    ${action}_shadowsocks
    ;;
    *)
    echo "Arguments error! [${action}]"
    echo "Usage: `basename $0` {install|uninstall}"
    ;;
esac
#0
