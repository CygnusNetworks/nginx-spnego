### docker-nginx-spnego

Container image providing NGINX with the SPNEGO/Kerberos authentication module preinstalled.

The image builds the SPNEGO module directly from [its source](https://github.com/stnoonan/spnego-http-auth-nginx-module) against the NGINX version in the official `nginx:stable-alpine` image. It does not use a prebuilt module image or package. Both build stages use the same NGINX base image so the dynamic module matches the NGINX binary in the final image.

#### What’s inside
- Base: official `nginx:stable-alpine`
- SPNEGO dynamic module compiled from the latest upstream release
- Kerberos runtime libraries; build tools and source code are excluded from the final image

#### Supported tags
- `latest` and `stable` point to the same image. A daily check publishes a new build only when the official `nginx:stable-alpine` image digest or latest SPNEGO release changes. A missing or stale `stable` tag is updated from `latest` without rebuilding.

To build locally, run `docker build -t nginx-spnego:local .`. The defaults use `nginx:stable-alpine` and the SPNEGO v1.1.3 source commit. To choose another compatible base or source revision, set `NGINX_IMAGE` and `SPNEGO_COMMIT`, for example:

```
docker build --build-arg NGINX_IMAGE=nginx:1.30.5-alpine \
  --build-arg SPNEGO_COMMIT=005723a3f5cadcf2da6ebbde8caad758555da11b \
  -t nginx-spnego:local .
```

#### How to use
1) Pull the image

```
docker pull ghcr.io/cygnusnetworks/nginx-spnego:latest
# or Docker Hub:
docker pull cygnusnetworks/nginx-spnego:latest
# The same image is also available under the stable tag:
docker pull ghcr.io/cygnusnetworks/nginx-spnego:stable
docker pull cygnusnetworks/nginx-spnego:stable
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
  cygnusnetworks/nginx-spnego:latest
```

Refer to the SPNEGO module documentation for additional directives such as `auth_gss_service_name`, `auth_gss_force_realm`, etc.

#### CI and publishing

This repository includes a GitHub Actions workflow that:
- Updates the Docker Hub description from this `README.md`
- Checks the official `nginx:stable-alpine` image digest and latest SPNEGO release daily at 03:17 UTC; rebuilds and publishes to GitHub Container Registry and Docker Hub only when either upstream changes (or a `latest` tag is missing)
- Records the NGINX base digest and SPNEGO source commit as image labels so subsequent checks can detect changes
- Builds for `linux/amd64` and `linux/arm64` and checks that NGINX can load the compiled module before publishing
- Adds an empty keepalive commit after 45 days without repository commits so GitHub does not disable scheduled builds for inactivity
- Publishes the `latest` and `stable` tags for the same image; repairs a missing or outdated `stable` tag without rebuilding
- Allows a manual rebuild via **Run workflow** with the `force` input, for example after changing the Dockerfile without an upstream update

#### Credits
Thanks to the [SPNEGO module maintainers](https://github.com/stnoonan/spnego-http-auth-nginx-module) and the [NGINX project](https://nginx.org/) for the upstream sources.
