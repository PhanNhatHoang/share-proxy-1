


install_3proxy() {
    echo "installing 3proxy"
    mkdir -p /3proxy
    bsdtar -xvf- $WORKDIR "$WORKDIR/3proxy-0.9.3.tar.gz"
    cd "$WORKDIR/3proxy-0.9.3"
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
    mv "$WORKDIR/3proxy-0.9.3/bin/3proxy" /usr/local/etc/3proxy/bin/
    echo "* hard nofile 999999" >>  /etc/security/limits.conf
    echo "* soft nofile 999999" >>  /etc/security/limits.conf
    echo "net.ipv6.conf.$main_interface.proxy_ndp=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.proxy_ndp=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.forwarding=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    echo "net.ipv6.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
    sysctl -p
    systemctl stop firewalld
    systemctl disable firewalld

}

yum -y update >/dev/null

yum -y install wget >/dev/null

yum -y install gcc net-tools bsdtar zip make >/dev/null

yum -y install java-1.8.0-openjdk >/dev/null

WORKDIR="/home/proxy-installer"
mkdir $WORKDIR && cd $_

install_3proxy


