ARG NGINX_IMAGE=nginx:stable-alpine
ARG SPNEGO_COMMIT=005723a3f5cadcf2da6ebbde8caad758555da11b

FROM ${NGINX_IMAGE} AS nginx-base

FROM nginx-base AS builder
ARG SPNEGO_COMMIT
# Primary key fingerprints of the NGINX release signers listed on https://nginx.org/en/pgp_keys.html
# (Roman Arutyunyan, Sergey Kandaurov, Sergey Budnevitch, Konstantin Pavlov)
ARG NGINX_PGP_KEYS="arut pluknet sb thresh"
ARG NGINX_PGP_FINGERPRINTS="43387825DDB1BB97EC36BA5D007C8D7C15D87369 D6786CE303D9A9022998DC6CC8464D549AF75C0A 7338973069ED3F443F4D37DFA64FD5B17ADB39A8 13C82A63B603576156E30A4EA0EA981B66B0D967"

RUN set -eux; \
    apk add --no-cache build-base curl gnupg krb5-dev openssl-dev pcre2-dev zlib-dev; \
    nginx_version="$(nginx -v 2>&1 | sed 's@^nginx version: nginx/@@')"; \
    curl -fsSL "https://nginx.org/download/nginx-${nginx_version}.tar.gz" -o /tmp/nginx.tar.gz; \
    curl -fsSL "https://nginx.org/download/nginx-${nginx_version}.tar.gz.asc" -o /tmp/nginx.tar.gz.asc; \
    export GNUPGHOME="$(mktemp -d)"; \
    for key in ${NGINX_PGP_KEYS}; do \
        curl -fsSL "https://nginx.org/keys/${key}.key" | gpg --batch --import; \
    done; \
    gpg --batch --status-file /tmp/gpg.status --verify /tmp/nginx.tar.gz.asc /tmp/nginx.tar.gz; \
    signer="$(awk '$2 == "VALIDSIG" { print $12 }' /tmp/gpg.status)"; \
    case " ${NGINX_PGP_FINGERPRINTS} " in \
        *" ${signer:-none} "*) ;; \
        *) echo "nginx-${nginx_version}.tar.gz is signed by unexpected key ${signer:-none}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://codeload.github.com/stnoonan/spnego-http-auth-nginx-module/tar.gz/${SPNEGO_COMMIT}" -o /tmp/spnego.tar.gz; \
    mkdir /tmp/nginx-src /tmp/spnego-src; \
    tar -xzf /tmp/nginx.tar.gz -C /tmp/nginx-src --strip-components=1; \
    tar -xzf /tmp/spnego.tar.gz -C /tmp/spnego-src --strip-components=1; \
    cd /tmp/nginx-src; \
    ./configure --with-compat --add-dynamic-module=/tmp/spnego-src; \
    make modules

FROM nginx-base
ARG NGINX_IMAGE
ARG NGINX_BASE_DIGEST
ARG SPNEGO_COMMIT
ARG BUILD_RECIPE
LABEL org.opencontainers.image.base.name="${NGINX_IMAGE}"
LABEL org.opencontainers.image.base.digest="${NGINX_BASE_DIGEST}"
LABEL org.cygnusnetworks.spnego-source-revision="${SPNEGO_COMMIT}"
LABEL org.cygnusnetworks.build-recipe="${BUILD_RECIPE}"

RUN apk add --no-cache krb5-libs
COPY --from=builder /tmp/nginx-src/objs/ngx_http_auth_spnego_module.so /usr/lib/nginx/modules/ngx_http_auth_spnego_module.so
RUN nginx -t -g 'load_module /usr/lib/nginx/modules/ngx_http_auth_spnego_module.so;'
