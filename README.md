# Nginx builder on MinGW

[Nginx](https://www.nginx.com/) build scripts on [MinGW/MSYS2](https://www.msys2.org/) with builtin libraries for **Windows**

## Prerequisites

- Follow the instructions to install [MinGW/MSYS2](https://www.msys2.org/)

- Install `MinGW` toolchain via `pacman` command in a `MSYS2` terminal

```bash
pacman -S --needed --noconfirm autotools patch autogen texinfo texinfo-tex \
  mingw-w64-x86_64-{gcc,make,pkgconf,tools,libmangle}
```

- Install required/optional libraries for `Nginx`

```bash
pacman -U https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-openssl-1.1.1.s-1-any.pkg.tar.zst
pacman -S --needed --noconfirm mingw-w64-x86_64-{pcre2,libxslt,geoip,libgd}
```

## Usage Examples

- Use the specific builder

```bash
git clone --depth=1 https://github.com/thachnn/nginx-build-mingw.git -b v1.23.3
```

- Start the `MinGW` shell

```batch
msys2_shell -mingw -defterm -no-start
```

- Build a previous version of `Nginx`

```bash
NGINX_TAG=1.22.1 SCRATCH_DIR=. ./nginx-build-mingw/build.sh
```

- Build with some additional patches

```bash
NGINX_TAG=1.23.3 CUSTOM_PATCH='1 2' ./nginx-build-mingw/build.sh
```

- Build with some additional modules, such as `dav-ext`

```bash
git clone --depth=1 https://github.com/arut/nginx-dav-ext-module.git -b v3.0.0 dav-ext-module

NGINX_TAG=1.23.4 CUSTOM_PATCH=1 ./nginx-build-mingw/build.sh \
  --with-{http_xslt,http_geoip,stream_geoip}_module --add-module=../dav-ext-module
```

- Build `Nginx` with dynamic libraries/modules

```bash
git clone --depth=1 https://github.com/openresty/headers-more-nginx-module.git -b v0.34 headers-more

NGINX_TAG=1.22.1 CUSTOM_PATCH='1 2' ./nginx-build-mingw/build.sh \
  --with-{pcre,zlib,openssl}=NONE --with-http_xslt_module=dynamic --add-dynamic-module=../headers-more
```

- Build static `Nginx` with separated modules

```bash
NGINX_TAG=1.23.4 CUSTOM_PATCH=1 USE_LIBXSLT=YES USE_GEOIP=YES USE_LIBGD=YES ./nginx-build-mingw/build.sh \
  --with-{http_xslt,http_geoip,stream_geoip,http_image_filter}_module=dynamic \
  --add-dynamic-module=../{dav-ext-module,headers-more}
```
