# Nginx builder on MinGW

Static [Nginx](https://www.nginx.com/) build scripts on [MinGW/MSYS2](https://www.msys2.org/)
with builtin libraries for **Windows**

## Prerequisites

- Install `MinGW` / `MSYS2` for **Windows**

- Install `MinGW` build tools via `pacman`

```bash
pacman -S --needed --noconfirm autoconf autogen automake-wrapper libtool m4 make patch pkgconf \
 diffutils gawk file grep sed texinfo texinfo-tex wget \
 mingw-w64-x86_64-binutils mingw-w64-x86_64-crt-git mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-libs \
 mingw-w64-x86_64-headers-git mingw-w64-x86_64-make mingw-w64-x86_64-pkgconf mingw-w64-x86_64-tools-git \
 mingw-w64-x86_64-libmangle-git mingw-w64-x86_64-libwinpthread-git mingw-w64-x86_64-winpthreads-git \
 mingw-w64-x86_64-libxslt
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
NGINX_TAG=1.22.1 ./nginx-build-mingw/build.sh
```

- Build with some additional patches

```bash
NGINX_TAG=1.23.3 CUSTOM_PATCH='1 2' ./nginx-build-mingw/build.sh
```

- Build with some additional modules, such as `dav-ext`

```bash
git clone --depth=1 https://github.com/arut/nginx-dav-ext-module.git -b v3.0.0 dav-ext-module

NGINX_TAG=1.23.4 CUSTOM_PATCH=1 ./nginx-build-mingw/build.sh \
 --with-cc-opt='-DFD_SETSIZE=1024 -s -O2 -fno-strict-aliasing -DLIBXML_STATIC -DLIBXSLT_STATIC -DLIBEXSLT_STATIC' \
 --with-http_xslt_module \
 --add-module=../dav-ext-module
```
