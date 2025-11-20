docker-nginx-spnego
====================

Container recipe for an NGINX image with the `auth_spnego` (Kerberos/Negotiate) authentication module installed on top of the official `nginx` image.

This image is built in two stages:
- Stage 1 pulls prebuilt dynamic module packages from the base image `chocolatefrappe/nginx-modules` (see reference below).
- Stage 2 starts from the official `nginx` image and installs those module APKs into the final image.

Key reference: the base image providing the prebuilt modules is
- Docker Hub: https://hub.docker.com/r/chocolatefrappe/nginx-modules
- Source: https://github.com/chocolatefrappe/nginx-modules


What this repository provides
-----------------------------
- A multi-stage `Dockerfile` that installs the `auth_spnego` dynamic module for NGINX.
- Uses `NGINX_VERSION` build argument to select the NGINX upstream tag and the matching module package set from `chocolatefrappe/nginx-modules`.

Notes and compatibility
-----------------------
- This Dockerfile currently targets Alpine-based NGINX images only, because it installs module packages with `apk`.
  - Default: `NGINX_VERSION=stable-alpine` (see the `Dockerfile`).
  - Example: `1.27.1-alpine`.
- Debian/Ubuntu variants (non-Alpine) are not supported by this Dockerfile as written.


Build
-----
```
docker build \
  --build-arg NGINX_VERSION=stable-alpine \
  -t my-nginx-spnego .
```

To pin a specific NGINX release (Alpine):
```
docker build \
  --build-arg NGINX_VERSION=1.27.1-alpine \
  -t my-nginx-spnego:1.27.1-alpine .
```


How it works (quick tour)
-------------------------
- The first stage copies from `chocolatefrappe/nginx-modules:${NGINX_VERSION}-auth-spnego` into `/tmp/nginx-modules`.
- The second stage starts from `nginx:${NGINX_VERSION}` and installs all available module APKs found in `/tmp/nginx-modules/packages`.
- The APKs provide NGINX dynamic modules (i.e., `.so` files) and any related metadata/config snippets.


Using the module in NGINX
-------------------------
Most setups will need to explicitly load the module and then configure SPNEGO auth. A minimal example:

```
# nginx.conf
load_module modules/ngx_http_auth_spnego_module.so;

events {}

http {
  server {
    listen 80;
    server_name _;

    location / {
      # Enable SPNEGO (Kerberos) auth
      auth_gss on;
      auth_gss_keytab /etc/nginx/krb5.keytab;
      auth_gss_service_name HTTP;   # typically HTTP/<hostname>
      auth_gss_allow_basic_fallback on;  # optional

      proxy_pass http://upstream_app;
    }
  }
}
```

You must also provide Kerberos configuration and keytab material to the container (for example):

```
docker run -d --name nginx-spnego \
  -p 8080:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v $(pwd)/krb5.conf:/etc/krb5.conf:ro \
  -v $(pwd)/krb5.keytab:/etc/nginx/krb5.keytab:ro \
  my-nginx-spnego
```

For module directives and advanced options, refer to the upstream module documentation, e.g.:
- https://github.com/stnoonan/spnego-http-auth-nginx-module


Security and production notes
-----------------------------
- Ensure your keytab is mounted read-only and with least privilege.
- Keep `NGINX_VERSION` updated to receive security patches from the base `nginx` image.
- Consider running as a non-root user and using a minimal configuration footprint for production.


Acknowledgements
----------------
- `chocolatefrappe/nginx-modules` for providing prebuilt NGINX dynamic modules used by this image.
- The NGINX open source project and the `auth_spnego` module authors/maintainers.
