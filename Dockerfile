# Original credit: https://github.com/jpetazzo/dockvpn

# Smallest base image
FROM ubuntu:18.04@sha256:4bc3ae6596938cb0d9e5ac51a1152ec9dcac2a1c50829c74abd9c4361e321b26

LABEL maintainer="lawtancool"

# Testing: pamtester
#RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
#    apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester && \
#    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
#    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

RUN apt-get update && apt-get install -y wget tar unzip build-essential libssl-dev iproute2 liblz4-dev liblzo2-dev libpam0g-dev libpkcs11-helper1-dev libsystemd-dev easy-rsa iptables pkg-config && \
    wget http://swupdate.openvpn.org/community/releases/openvpn-2.5.0.tar.gz && tar xvf openvpn-2.5.0.tar.gz && \
    wget https://github.com/Tunnelblick/Tunnelblick/archive/v3.8.5beta02.zip && unzip v3.8.5beta02.zip && \
    cp Tunnelblick-3.8.5beta02/third_party/sources/openvpn/openvpn-2.5.0/patches/*.diff openvpn-2.5.0 && \
    cd openvpn-2.5.0 && \
    patch -p1 < 02-tunnelblick-openvpn_xorpatch-a.diff && \
    patch -p1 < 03-tunnelblick-openvpn_xorpatch-b.diff && \
    patch -p1 < 04-tunnelblick-openvpn_xorpatch-c.diff && \
    patch -p1 < 05-tunnelblick-openvpn_xorpatch-d.diff && \
    patch -p1 < 06-tunnelblick-openvpn_xorpatch-e.diff && \
    ./configure --disable-systemd --enable-async-push --enable-iproute2 && \
    make && make install && \
    cd .. && rm -r openvpn-2.5.0 && rm -r Tunnelblick-3.8.5beta02

# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

# Prevents refused client connection because of an expired CRL
ENV EASYRSA_CRL_DAYS 3650

VOLUME ["/etc/openvpn"]

# Internally uses port 1194, remap if needed using `docker run -p 443:1194/tcp`
EXPOSE 1194

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/
