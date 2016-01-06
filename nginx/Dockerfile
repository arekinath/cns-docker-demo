FROM alpine

ENV NGINX_VERSION 1.8.0
ENV NGX_DEVEL_KIT_VERSION 0.2.19
ENV LUA_NGINX_VERSION 0.9.20
ENV LPEG_VERSION 1.0.0
ENV DYNUPSTREAM_TAG master

RUN	export NGINX_URL=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
	export LPEG_URL=http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-${LPEG_VERSION}.tar.gz && \
	export LUA_NGINX_URL=https://github.com/openresty/lua-nginx-module/archive/v${LUA_NGINX_VERSION}.tar.gz && \
	export NGX_DEVEL_KIT_URL=https://github.com/simpl/ngx_devel_kit/archive/v${NGX_DEVEL_KIT_VERSION}.tar.gz && \
	export DYNUPSTREAM_REPO=https://github.com/GUI/nginx-upstream-dynamic-servers && \
	apk --update add openssl-dev pcre-dev zlib-dev wget openssl pcre libpcre16 libpcre32 zlib \
		build-base lua-dev lua git libaio-dev libaio linux-headers && \
	mkdir -p /tmp/src && \
	cd /tmp/src && \
	wget ${LPEG_URL} && \
	tar -zxvf lpeg-${LPEG_VERSION}.tar.gz && \
	wget ${NGINX_URL} && \
	tar -zxvf nginx-${NGINX_VERSION}.tar.gz && \
	wget -O lua-nginx-module-${LUA_NGINX_VERSION}.tar.gz ${LUA_NGINX_URL} && \
	tar -zxvf lua-nginx-module-${LUA_NGINX_VERSION}.tar.gz && \
	wget -O ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.tar.gz ${NGX_DEVEL_KIT_URL} && \
	tar -zxvf ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.tar.gz && \
	git clone -b ${DYNUPSTREAM_TAG} ${DYNUPSTREAM_REPO} nginx-upstream-dynamic-servers && \
	cd /tmp/src/lpeg-${LPEG_VERSION} && \
	make && \
	mkdir -p /usr/lib/lua/5.1 && \
	cp lpeg.so /usr/lib/lua/5.1/ && \
	cd /tmp/src/nginx-${NGINX_VERSION} && \
	./configure \
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--pid-path=/var/run/nginx/nginx.pid \
		--lock-path=/var/run/nginx/nginx.lock \
		--http-log-path=/var/log/nginx/access.log \
		--error-log-path=/var/log/nginx/error.log \
		--http-client-body-temp-path=/var/tmp/nginx/client_body \
		--http-proxy-temp-path=/var/tmp/nginx/proxy \
		--http-fastcgi-temp-path=/var/tmp/nginx/fastcgi \
		--http-uwsgi-temp-path=/var/tmp/nginx/uwsgi \
		--http-scgi-temp-path=/var/tmp/nginx/scgi \
		--user=nginx \
		--group=nginx \
		--with-ipv6 \
		--with-file-aio \
		--with-pcre-jit \
		--with-http_dav_module \
		--with-http_ssl_module \
		--with-http_gzip_static_module \
		--with-http_spdy_module \
		--add-module="/tmp/src/ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}" \
		--add-module="/tmp/src/lua-nginx-module-${LUA_NGINX_VERSION}" \
		--add-module="/tmp/src/nginx-upstream-dynamic-servers" && \
	make -j4 && \
	make install && \
	addgroup nginx && adduser -h /var/tmp/nginx -S -D -H nginx && \
	mkdir -p /var/log/nginx /var/run/nginx /var/tmp/nginx && \
	chown nginx:nginx /var/log/nginx /var/run/nginx /var/tmp/nginx && \
	apk del build-base linux-headers libaio-dev pcre-dev openssl-dev zlib-dev lua-dev git && \
	rm -rf /tmp/src && \
	rm -rf /var/cache/apk/*

WORKDIR /etc/nginx
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
