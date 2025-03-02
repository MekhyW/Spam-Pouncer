FROM openresty/openresty:alpine

RUN mkdir -p /etc/ssl/certs /etc/ssl/private

COPY cert.pem /etc/ssl/certs/cert.pem
COPY key.pem /etc/ssl/private/key.pem

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

COPY spam_check.lua /usr/local/openresty/nginx/conf/spam_check.lua
COPY antispam.lua /usr/local/openresty/site/lualib/antispam.lua
COPY utf8.lua /usr/local/openresty/site/lualib/utf8.lua


EXPOSE 80 443

# Start OpenResty
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

