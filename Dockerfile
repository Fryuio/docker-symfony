FROM php:8.2-fpm-alpine

ARG USER
WORKDIR /var/www/html

COPY --from=composer:latest  /usr/bin/composer /usr/bin/composer

RUN apk add shadow
RUN apk add --no-cache bash
RUN apk add --update nodejs=18.17.0-r0 && apk add --update npm
RUN apk add doas; \
    adduser ${USER} -G wheel; \
    echo 'permit :wheel as root' > /etc/doas.d/doas.conf

RUN apk add git

RUN apk add --update linux-headers
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install xdebug-3.2.0 \
    && docker-php-ext-enable xdebug \
    && apk del -f .build-deps

RUN apk add libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql

RUN echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.log=/var/www/html/xdebug/xdebug.log" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/xdebug.ini

RUN chown www-data:www-data /var/www && chmod 755 /var/www
RUN chown -R www-data:www-data /var/www && chmod -R 774 /var/www
RUN usermod -a -G www-data ${USER}
USER ${USER}

RUN composer create-project symfony/skeleton:"6.4.*@dev" /var/www/html
RUN cd /var/www/html
RUN composer require webapp

ENV SHELL /bin/bash


