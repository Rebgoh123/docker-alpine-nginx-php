FROM nginx:alpine

LABEL maintainer="Rebecca Goh <rebeccagoh@outlook.com>"

## COPY command simply copies a file from the host filesystem into the image when the image is building

COPY start.sh /start.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
COPY site.conf /etc/nginx/sites-available/default.conf

## Add commands that will instruct Alpine Linux to install the packages we will need inside the image.

RUN apk add --update \
php7 \
php7-fpm \
php7-pdo \
php7-curl \
php7-pdo_mysql \
php7-mcrypt \
php7-mbstring \
php7-json \
php7-mbstring \
php7-xml \
php7-openssl \
php7-tokenizer \
php7-json \
php7-phar \
php7-zip \
php7-dom \
php7-session \
php7-zlib && \
php7 -r "copy('http://getcomposer.org/installer', 'composer-setup.php');" && \
php7 composer-setup.php --install-dir=/usr/bin --filename=composer && \
php7 -r "unlink('composer-setup.php');" && \
rm -R /usr/bin/php && \
ln -s /usr/bin/php7 /usr/bin/php && \
ln -s /etc/php7/php.ini /etc/php7/conf.d/php.ini

##Supervisor will help us keep our Nginx running in the background and stop the container from exiting.
##Bash, which is optional so we can SSH into our container when it is running

RUN apk add --update bash \
openssh-client \
supervisor

##Add some files in the filesystem of our image to suit our needs.

RUN mkdir -p /etc/nginx && \
mkdir -p /etc/nginx/sites-available && \
mkdir -p /etc/nginx/sites-enabled && \
mkdir -p /run/nginx && \
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf && \
mkdir -p /var/log/supervisor && \
rm -Rf /var/www/* && \
chmod 755 /start.sh

RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" \
-e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" \
/etc/php7/php.ini && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" \
-e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
-e "s/user = nobody/user = nginx/g" \
-e "s/group = nobody/group = nginx/g" \
-e "s/;listen.mode = 0660/listen.mode = 0666/g" \
-e "s/;listen.owner = nobody/listen.owner = nginx/g" \
-e "s/;listen.group = nobody/listen.group = nginx/g" \
-e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
-e "s/^;clear_env = no$/clear_env = no/" \
/etc/php7/php-fpm.d/www.conf

##The EXPOSE command informs Docker that the container listens on the specified network ports at runtime. 
##The WORKDIR command sets the working directory for our commands going forth. It’ll also create the /var/www directory.

EXPOSE 443 80
WORKDIR /var/www

##Whenever we build our image, the file start.sh will be executed

CMD ["/start.sh"]