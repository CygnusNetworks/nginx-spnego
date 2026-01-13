# NGINX_VERSION: Use `{version}` for debian variant and `{version}-alpine` for alpine variant
# When building via CI, NGINX_VERSION is extracted from the module image to ensure compatibility
ARG NGINX_VERSION=stable-alpine

# Modules (always use stable-alpine tag, version is embedded in the packages)
FROM chocolatefrappe/nginx-modules:stable-alpine-auth-spnego AS mod-auth-spnego

# NGINX (use specific version passed from CI, or stable-alpine as default)
FROM nginx:${NGINX_VERSION}

COPY --from=mod-auth-spnego  / /tmp/nginx-modules

# Alpine
RUN set -ex \
    && cd /tmp/nginx-modules \
    && for mod in module-available.d/*; do \
            module=$(basename $mod); \
            apk add --no-cache --allow-untrusted packages/nginx-module-${module}-[0-9]*.apk; \
        done \
    && rm -rf /tmp/nginx-modules
