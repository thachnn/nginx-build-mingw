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
cat "$_SC_DIR"/0*.patch | patch -p1 -Ntl
[[ -z "$CUSTOM_PATCH" ]] || for x in $CUSTOM_PATCH; do patch -p1 -Ntl -i "$_SC_DIR/$x"*.patch; done

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
  --with-ld-opt='-Wl,--gc-sections,--build-id=none -Wl,--exclude-libs=ALL'
)
# --with-pcre-jit
auto/configure "${_CONFIG_ARGS[@]}" "$@"
sed -i 's/\(-exclude-libs=ALL'\''\?\) .*"$/\1"/' objs/ngx_auto_config.h

# build
make -j2 || ( [[ -s objs/nginx.exe ]] && make -j2 )
for x in objs/*.{exe,so}; do strip -o "${x##*/}" -d --strip-unneeded "${x}" || true; done
[[ "$(ls -S1 {,objs/}nginx.exe | head -1)" == nginx.exe ]] || mv -f *.{exe,so} objs/ || true

# make changes
make -f docs/GNUmakefile changes
mv -f tmp/*/CHANGES* docs/text/ && rm -rf tmp

# copy licenses
if [[ -d "${_LIC_PATH=$MINGW_PREFIX/share/licenses}" ]]; then
  cp -pf "$_LIC_PATH/zlib/LICENSE" docs/text/zlib.LICENSE
  for x in "$_LIC_PATH"/pcre*/LICENCE; do cp -pf "$x" docs/text/PCRE.LICENCE; done
  for x in "$_LIC_PATH"/openssl*/LICENSE; do cp -pf "$x" docs/text/OpenSSL.LICENSE; done
fi

# separate nginx.conf file
mkdir -p conf/{http.d,modules}
sed -n '/^    # HTTPS /,/^    #}/p' conf/nginx.conf > conf/http.d/https-server.conf && \
  sed -i '/^    # HTTPS /,/^    #}/d' conf/nginx.conf
sed -n '/^    # another virtual/,/^    #}/p' conf/nginx.conf > conf/http.d/somename-host.conf && \
  sed -i '/^    # another virtual/,/^    #}/d' conf/nginx.conf
sed -n '/^    server /,/^    }/p' conf/nginx.conf > conf/http.d/default-server.conf && \
  sed -i '/^    server /,/^    }/d' conf/nginx.conf
#
sed -i 's/^    //' conf/http.d/*.conf
for x in objs/*.so; do
  x="${x##*/ngx_}"; echo "load_module  modules/ngx_$x;" > "conf/modules/${x%_module.*}.conf" || true
done

# package
rm -rf temp; mkdir -p temp/logs
tar -czf "../${_PKG}-$(gcc -dumpmachine | cut -d'-' -f1).tgz" \
  --transform='s,^docs/html,html,;s,^docs/text,docs,;s,^temp/,,;s,^objs/nginx,nginx,;s,^objs/,modules/,' \
   objs/*.{exe,so} contrib conf docs/text docs/html temp
