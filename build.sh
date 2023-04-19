#!/bin/bash
set -xe
_SC_DIR="$(cd "`dirname "$0"`"; pwd)"

: "${NGINX_TAG:=1.22.1}"
: "${SCRATCH_DIR:=$(cd "$_SC_DIR/.."; pwd)}"

_TAG="release-$NGINX_TAG"
_PKG="nginx-$NGINX_TAG"

# download
cd "$SCRATCH_DIR"
[[ -s "$_TAG.tar.gz" ]] || curl -OkfSL "https://github.com/nginx/nginx/archive/$_TAG.tar.gz"
rm -rf "$_PKG"; tar -xf "$_TAG.tar.gz" && mv "nginx-$_TAG" "$_PKG"

cd "$_PKG"
# apply patches
cat "$_SC_DIR"/0*.patch | patch -p1 -Nt
[[ -z "$CUSTOM_PATCH" ]] || for x in $CUSTOM_PATCH; do patch -p1 -Nt -i "$_SC_DIR/$x"*.patch; done

# configure
_CONFIG_ARGS=(
  --with-cc=gcc \
  --prefix= \
  --conf-path=conf/nginx.conf \
  --pid-path=logs/nginx.pid \
  --http-log-path=logs/access.log \
  --error-log-path=logs/error.log \
  --sbin-path=nginx.exe \
  --http-client-body-temp-path=temp/client_body_temp \
  --http-proxy-temp-path=temp/proxy_temp \
  --http-fastcgi-temp-path=temp/fastcgi_temp \
  --http-scgi-temp-path=temp/scgi_temp \
  --http-uwsgi-temp-path=temp/uwsgi_temp \
  --with-cc-opt='-DFD_SETSIZE=1024 -s -O2 -fno-strict-aliasing -pipe' \
  --with-pcre=YES \
  --with-zlib=YES \
  --with-http_v2_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_stub_status_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_auth_request_module \
  --with-http_random_index_module \
  --with-http_secure_link_module \
  --with-http_slice_module \
  --with-mail \
  --with-stream \
  --with-openssl=YES \
  --with-openssl-opt='no-tests -D_WIN32_WINNT=0x0501' \
  --with-http_ssl_module \
  --with-mail_ssl_module \
  --with-stream_ssl_module \
  --with-ld-opt='-Wl,--gc-sections,--build-id=none'
)
# --with-pcre-jit
auto/configure "${_CONFIG_ARGS[@]}" "$@"

# build
make -j2
strip -o nginx.exe -s objs/nginx.exe

# package
rm -rf temp; mkdir -p temp/logs
tar -czf "../${_PKG}-$(gcc -dumpmachine | cut -d'-' -f1).tgz" \
  --transform='s,^docs/html,html,;s,^docs/text,docs,;s,^temp/logs,logs,' \
  nginx.exe contrib conf docs/text docs/html temp
