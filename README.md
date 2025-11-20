### docker-nginx-spnego

Container image providing NGINX with the SPNEGO/Kerberos authentication module preinstalled.

This image builds on the chocolatefrappe/nginx-modules base image, which supplies prebuilt dynamic NGINX modules as Alpine packages. We copy the module artifacts from that image and install them into an `nginx` base image so you can `load_module` and use SPNEGO auth in your own NGINX configuration.

- Base modules image: `chocolatefrappe/nginx-modules`
  - Docker Hub: https://hub.docker.com/r/chocolatefrappe/nginx-modules
  - Source: https://github.com/chocolatefrappe/docker-nginx-modules

#### What’s inside
- Base: `nginx:${NGINX_VERSION}` (default: `stable-alpine`)
- Adds the SPNEGO auth module from `chocolatefrappe/nginx-modules` (`-auth-spnego` variant)
- Installs the module(s) as Alpine packages during build

The key lines from the `Dockerfile`:

```
ARG NGINX_VERSION=stable-alpine
FROM chocolatefrappe/nginx-modules:${NGINX_VERSION}-auth-spnego AS mod-auth-spnego
FROM nginx:${NGINX_VERSION}
COPY --from=mod-auth-spnego / /tmp/nginx-modules
RUN set -ex \
  && cd /tmp/nginx-modules \
  && for mod in module-available.d/*; do \
       module=$(basename $mod); \
       apk add --no-cache --allow-untrusted packages/nginx-module-${module}-${NGINX_VERSION}*.apk; \
     done \
  && rm -rf /tmp/nginx-modules
```

#### Supported tags
- `latest` (tracks the default `ARG NGINX_VERSION=stable-alpine`)
- Version tags that mirror repo tags `v*` in this repository (see GitHub Releases)

Note: You can rebuild the image yourself with a different NGINX base by setting the build argument `NGINX_VERSION`, e.g. `1.27.2-alpine` or `stable-alpine`.

#### How to use
1) Pull the image

```
docker pull ghcr.io/<owner>/<repo>:latest
# or Docker Hub (if published):
docker pull <dockerhub_user>/<repo>:latest
```

2) Load the SPNEGO module in your `nginx.conf` and configure auth

On Alpine-based NGINX, dynamic modules are typically located under `/usr/lib/nginx/modules`. Load the module at the top level (main context), then add `auth_gss` directives in the location/server where you want protection.

Example `nginx.conf` snippet:

```
load_module /usr/lib/nginx/modules/ngx_http_auth_spnego_module.so;

events {}

http {
  server {
    listen 80;
    server_name _;

    # Protect everything under /
    location / {
      auth_gss on;               # enable SPNEGO/Kerberos auth
      auth_gss_realm EXAMPLE.COM; # your Kerberos realm
      auth_gss_keytab /etc/nginx/krb5.keytab; # mount a keytab with the service principal

      proxy_pass http://upstream_app;
    }
  }
}
```

3) Provide Kerberos configuration and keytab

- Mount your `krb5.conf` and keytab into the container, for example:

```
docker run \
  -v $(pwd)/krb5.conf:/etc/krb5.conf:ro \
  -v $(pwd)/krb5.keytab:/etc/nginx/krb5.keytab:ro \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  ghcr.io/<owner>/<repo>:latest
```

Refer to the SPNEGO module documentation for additional directives such as `auth_gss_service_name`, `auth_gss_force_realm`, etc.

#### Building locally with a custom NGINX version

```
docker build \
  --build-arg NGINX_VERSION=1.27.2-alpine \
  -t my-nginx-spnego:1.27.2 .
```

#### CI and publishing

This repository includes a GitHub Actions workflow that:
- Updates the Docker Hub description from this `README.md`
- Builds and publishes the image to GitHub Container Registry and Docker Hub
- Produces tags: `latest` and any `v*` tag pushed to the repo

#### Credits
Huge thanks to the `chocolatefrappe/nginx-modules` project for providing the prebuilt NGINX modules used here.
