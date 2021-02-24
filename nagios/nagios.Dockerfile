FROM centos:7

ENV NAGIOSADMIN_USER=nagiosadmin\
    NAGIOSADMIN_PASS=nagios\
    NAGIOS_BRANCH=nagios-4.4.5\
    NAGIOS_PLUGINS_BRANCH=release-2.2.1\
    NRPE_BRANCH=nrpe-3.2.1

RUN yum update -y && \
    yum install -y gcc \
    glibc glibc-common \
    unzip httpd php gd gd-devel \
    perl postfix \
    python36 python36-devel python36-pip \
    net-snmp net-snmp-utils epel-release \
    perl-Net-SNMP git which make \
    gettext automake autoconf openssl-devel \
    net-snmp net-snmp-utils

#groupadd -r nagios
#useradd -g nagios nagios

RUN cd /tmp && \
    git clone https://github.com/NagiosEnterprises/nagioscore.git -b $NAGIOS_BRANCH && \
    cd nagioscore && \
    ./configure && \
    make all && \
    make install-groups-users && \
    usermod -a -G nagios apache && \
    make install && \
    make install-init && \
    make install-commandmode && \
    make install-config && \
    make install-webconf && \
    htpasswd -b -c /usr/local/nagios/etc/htpasswd.users $NAGIOSADMIN_USER $NAGIOSADMIN_PASS && \
    cd /tmp && rm -rf nagioscore

RUN cd /tmp && \
    git clone https://github.com/nagios-plugins/nagios-plugins.git -b $NAGIOS_PLUGINS_BRANCH && \
    cd nagios-plugins && \
    ./tools/setup && \
    ./configure \
    --with-ipv6\
    --with-ping6-command="/bin/ping6 -n -U -W %d -c %d %s" && \
    make && \
    make install && \
    cd /tmp && rm -rf nagios-plugins

RUN cd /tmp                                                                  && \
    git clone https://github.com/NagiosEnterprises/nrpe.git -b $NRPE_BRANCH  && \
    cd nrpe                                                                  && \
    ./configure                                   \
    --with-need-dh=no  \
    && \
    make check_nrpe                                                          && \
    make clean                                                               && \
    cd /tmp && rm -rf nrpe

EXPOSE 80 443

VOLUME "/usr/local/nagios" "/etc/httpd/"

COPY run-httpd.sh /run-httpd.sh

RUN chmod +x run-httpd.sh

CMD ["/run-httpd.sh"]
