#!/bin/bash
#############################################
#                                           #
#            Saycheese kevops               #
#                                           #
#############################################

PHP_CONTAINER="php-saycheese"
NGX_CONTAINER="nginx-saycheese"
NGX_DOMAIN="saycheese.kevops.xyz"

mkdir -p /var/containers/$NGX_CONTAINER/etc/nginx/conf.d
mkdir -p /var/containers/share/var/www/html/{data,images}

git clone https://github.com/kevop-s/Saycheese.git /opt/Saycheese

cp -rf /opt/Saycheese/src/* /var/containers/share/var/www/html/
chmod 777 -R /var/containers/share/var/www/html/

cat<<-EOF > /var/containers/$NGX_CONTAINER/etc/nginx/conf.d/$NGX_DOMAIN.conf
server {
    listen 80;
    index index.php;
    server_name saycheese.kevops.xyz;
    root /var/www/html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php-fpm:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/html\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
}
EOF

docker run -d --name $PHP_CONTAINER \
    -v /var/containers/share/var/www/html:/var/www/html:z \
    -v /etc/localtime:/etc/localtime:ro \
    php:7-fpm

docker run -td --name $NGX_CONTAINER \
    -p 80:80 -p 443:443 \
    -v /var/containers/share/var/www/html:/var/www/html:z \
    -v /var/containers/$NGX_CONTAINER/var/log/nginx:/var/log/nginx:z \
    -v /var/containers/$NGX_CONTAINER/etc/nginx/conf.d:/etc/nginx/conf.d:z \
    -v /etc/localtime:/etc/localtime:ro \
    -h $NGX_CONTAINER.service \
    --link $PHP_CONTAINER:php-fpm \
    nginx