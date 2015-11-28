FROM ubuntu:14.04
MAINTAINER Pasi Eronen <pe@iki.fi>

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -qy \
    apache2 \
    libio-string-perl \
    libxml-writer-perl \
    libxml-xpath-perl \
    python2.7 \
    wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN a2enmod actions auth_digest cgi headers include proxy proxy_http
ADD 000-default.conf /etc/apache2/sites-available/000-default.conf
ADD servername.conf /etc/apache2/conf-enabled/servername.conf
ADD digest /var/local/loginmgr/digest
RUN wget -O /usr/lib/cgi-bin/pyht -nv http://tools.ietf.org/tools/pyht/pyht && chmod a+x /usr/lib/cgi-bin/pyht && ln -s python2.7 /usr/bin/python

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD /bin/bash
EXPOSE 80
