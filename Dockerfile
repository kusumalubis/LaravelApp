FROM php:8.1-apache

RUN apt-get update -y && apt-get install -y \
    openssl \
    zip \
    unzip \
    git \
    vim \
    curl \
    nodejs \
    npm \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev  \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    libonig-dev \
    libzip-dev \
    g++

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

#copy application
COPY . /var/www/html

WORKDIR /var/www/html

#apache configs + document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN echo $(grep $(hostname) /etc/hosts | cut -f1) laravel-app.dev >> /etc/hosts

#mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers

#start with base php config
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
RUN echo "memory_limit=1024M" >> "$PHP_INI_DIR/php.ini"
RUN echo "upload_max_filesize=64M" >> "$PHP_INI_DIR/php.ini"
RUN echo "post_max_size=64M" >> "$PHP_INI_DIR/php.ini"
RUN echo "max_execution_time=600" >> "$PHP_INI_DIR/php.ini"

#then add extensions
RUN docker-php-ext-install \
    bcmath \
    pcntl \
    mbstring \
    pdo_mysql \
    exif \
    zip

RUN docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype
RUN docker-php-ext-install -j$(nproc) gd

#composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Change current user to www
RUN useradd -G www-data,root -u 1000 -d /home/devuser devuser
RUN mkdir -p /home/devuser/.composer && \
    chown -R devuser:devuser /home/devuser

RUN service apache2 restart

EXPOSE 80

# RUN chmod +x ./laravel-install.sh
RUN chmod 755 ./laravel-install.sh

RUN chmod o+w ./storage/ -R

# CMD ["/bin/bash","-c","./laravel-install.sh"]

# CMD ["/bin/bash", "laravel-install.sh"]
# CMD ["/bin/bash","-c","./laravel-install.sh"]
