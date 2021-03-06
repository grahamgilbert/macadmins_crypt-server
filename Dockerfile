# Crypt Server Dockerfile
FROM phusion/passenger-customizable:0.9.11
MAINTAINER Pepijn Bruienne bruienne@umich.edu

# Basic env vars for apt and Passenger
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV TZ America/New_York

# DOCKER_CRYPT_* env vars configure the following possible settings in Crypt's
# settings.py:
# DOCKER_CRYPT_ADMINS = A list of lists (tuples) of names and email addresses of authorized admins
# DOCKER_CRYPT_ALLOWED = A list of allowed hosts or IP addresses, defaults to *
# DOCKER_CRYPT_LANG = Preferred language
# DOCKER_CRYPT_TZ = Time zone to use for GUI and logging

# To define multiple admins: Some Name,some@where.com:Another One,another@host.net
ENV DOCKER_CRYPT_ADMINS Admin User,admin@test.com
# ENV DOCKER_CRYPT_ALLOWED myhost,1.2.3.4,anotherhost.fqdn.com
ENV DOCKER_CRYPT_LANG en_US
ENV DOCKER_CRYPT_TZ America/New_York

CMD ["/sbin/my_init"]
RUN apt-get -y update
RUN /build/utilities.sh
RUN /build/python.sh

RUN apt-get -y install python-setuptools libapache2-mod-wsgi python-dev libpq-dev && easy_install pip && \
    git clone https://github.com/grahamgilbert/Crypt-Server.git /home/app/crypt && \
    pip install -r /home/app/crypt/setup/requirements.txt && \
    rm -f /etc/service/nginx/down

RUN pip install psycopg2==2.5.3
RUN mkdir -p /etc/my_init.d

# Add a modified settings.py that imports setting_import which in turn grabs
# Docker env vars, this way we separate out the main settings and Docker vars
ADD settings.py /home/app/crypt/fvserver/

ADD settings_import.py /home/app/crypt/fvserver/
ADD crypt.conf /etc/nginx/sites-enabled/
ADD crypt-env.conf /etc/nginx/main.d/crypt-env.conf
ADD django/ /home/app/crypt
ADD passenger_wsgi.py /home/app/crypt/
ADD run.sh /etc/my_init.d/run.sh

VOLUME ["/home/app/crypt/crypt/settings.py", "/home/app/crypt/db"]

EXPOSE 8000

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
