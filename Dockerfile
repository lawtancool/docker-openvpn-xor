# Original credit: https://github.com/jpetazzo/dockvpn

# Smallest base image
FROM ubuntu:18.04@sha256:134c7fe821b9d359490cd009ce7ca322453f4f2d018623f849e580a89a685e5d

LABEL maintainer="lawtancool"

# Testing: pamtester
#RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
#    apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester && \
#    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
#    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*
    
RUN apt-get update && apt-get install -y wget tar unzip build-essential libssl-dev iproute2 liblz4-dev liblzo2-dev libpam0g-dev libpkcs11-helper1-dev libsystemd-dev easy-rsa iptables pkg-config && \
    wget http://swupdate.openvpn.org/community/releases/openvpn-2.4.8.tar.gz && tar xvf openvpn-2.4.8.tar.gz && \
    wget https://github.com/Tunnelblick/Tunnelblick/archive/v3.8.2beta02.zip && unzip v3.8.2beta02.zip && \
    cp Tunnelblick-3.8.2beta02/third_party/sources/openvpn/openvpn-2.4.8/patches/*.diff openvpn-2.4.8 && \
    cd openvpn-2.4.8 && \
    patch -p1 < 02-tunnelblick-openvpn_xorpatch-a.diff && \
    patch -p1 < 03-tunnelblick-openvpn_xorpatch-b.diff && \
    patch -p1 < 04-tunnelblick-openvpn_xorpatch-c.diff && \
    patch -p1 < 05-tunnelblick-openvpn_xorpatch-d.diff && \
    patch -p1 < 06-tunnelblick-openvpn_xorpatch-e.diff && \
    ./configure --disable-systemd --enable-async-push --enable-iproute2 && \
    make && make install
    
# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

# Prevents refused client connection because of an expired CRL
ENV EASYRSA_CRL_DAYS 3650

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/
