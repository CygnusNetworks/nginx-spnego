ARG NGINX_IMAGE=nginx:stable-alpine
ARG SPNEGO_COMMIT=005723a3f5cadcf2da6ebbde8caad758555da11b

FROM ${NGINX_IMAGE} AS nginx-base

FROM nginx-base AS builder
ARG SPNEGO_COMMIT

RUN set -eux; \
    apk add --no-cache build-base curl krb5-dev openssl-dev pcre2-dev zlib-dev; \
    nginx_version="$(nginx -v 2>&1 | sed 's@^nginx version: nginx/@@')"; \
    curl -fsSL "https://nginx.org/download/nginx-${nginx_version}.tar.gz" -o /tmp/nginx.tar.gz; \
    curl -fsSL "https://codeload.github.com/stnoonan/spnego-http-auth-nginx-module/tar.gz/${SPNEGO_COMMIT}" -o /tmp/spnego.tar.gz; \
    mkdir /tmp/nginx-src /tmp/spnego-src; \
    tar -xzf /tmp/nginx.tar.gz -C /tmp/nginx-src --strip-components=1; \
    tar -xzf /tmp/spnego.tar.gz -C /tmp/spnego-src --strip-components=1; \
    cd /tmp/nginx-src; \
    ./configure --with-compat --add-dynamic-module=/tmp/spnego-src; \
    make modules

FROM nginx-base
ARG SPNEGO_COMMIT
LABEL org.cygnusnetworks.spnego-source-revision="${SPNEGO_COMMIT}"

RUN apk add --no-cache krb5-libs
COPY --from=builder /tmp/nginx-src/objs/ngx_http_auth_spnego_module.so /usr/lib/nginx/modules/ngx_http_auth_spnego_module.so
RUN nginx -t -g 'load_module /usr/lib/nginx/modules/ngx_http_auth_spnego_module.so;'
