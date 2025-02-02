FROM nginx

MAINTAINER Ladybird Web Solutions <support@ladybirdweb.com>

# Install necessary packages 
RUN apt-get update -y && apt-get install -y apt-transport-https ca-certificates wget software-properties-common

RUN curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
# PHP 7.1 Repo on Debian 11
RUN sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'

# Not support PHP 7.4^
RUN apt-get update -y && apt-get install -y curl git sl mlocate dos2unix \
    bash-completion openssl php7.1-xml php7.1-mbstring php7.1-zip php7.1-mysql \
    php7.1-opcache php7.1-json php7.1-curl php7.1-ldap php7.1-cgi php7.1-imap \
    php7.1-cli php7.1-fpm php7.1-common php7.1-bcmath libapache2-mod-php7.1 \
    cron && rm -rf /var/lib/apt/lists/*

# Only support Composer ~ Ver.1.7.2
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=1.7.2

RUN sed -i 's/user  nginx/user  www-data/g' /etc/nginx/nginx.conf

# Force PHP to log to nginx
RUN echo "catch_workers_output = yes" >> /etc/php/7.1/fpm/php-fpm.conf

# Enable php by default
ADD default.conf /etc/nginx/conf.d/default.conf

WORKDIR /usr/share/nginx/

RUN rm -rf *

# Clone the project from git
RUN git clone https://github.com/ladybirdweb/faveo-helpdesk.git .

RUN composer install
RUN chgrp -R www-data . storage bootstrap/cache
RUN chmod -R ug+rwx . storage bootstrap/cache

# Add to crontab file

RUN touch /etc/cron.d/faveo-cron

RUN echo '* * * * * php /usr/share/nginx/artisan schedule:run > /dev/null 2>&1' >>/etc/cron.d/faveo-cron

RUN chmod 0644 /etc/cron.d/faveo-cron

RUN crontab /etc/cron.d/faveo-cron

RUN sed -i "s/max_execution_time = .*/max_execution_time = 120/" /etc/php/7.1/fpm/php.ini

RUN php -m

CMD cron && service php7.1-fpm start && nginx -g "daemon off;"
