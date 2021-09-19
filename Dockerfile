FROM ubuntu:18.04

# Install extra dependencies
RUN apt-get update && apt-get install -y \
    git \
    make \
    cmake \
    libuv1-dev \
    libssl-dev \
    curl \
    autoconf \
    dpkg-dev \
    libncurses5-dev \
    libncursesw5-dev

# Install Erlang OTP 22
# NOTICE: Code above is added or changed
# NOTICE: Code below is from https://github.com/erlang/docker-erlang-otp/blob/5c0484719e5e38f0897af0726c585c48aebd73c1/22/Dockerfile

ENV OTP_VERSION="22.3.4.10" \
    REBAR3_VERSION="3.13.2"

LABEL org.opencontainers.image.version=$OTP_VERSION

# We'll install the build dependencies for erlang-odbc along with the erlang
# build process:
RUN set -xe \
    && OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz" \
    && OTP_DOWNLOAD_SHA256="cb986b97321dfff4d1fd32fc4bb8fe0f2fd3addfe0eedade787c9f3443e41cc9" \
    && runtimeDeps='libodbc1 \
            libsctp1 \
            libwxgtk3.0' \
    && buildDeps='unixodbc-dev \
            libsctp-dev \
            libwxgtk3.0-dev' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $runtimeDeps \
    && apt-get install -y --no-install-recommends $buildDeps \
    && curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
    && echo "$OTP_DOWNLOAD_SHA256  otp-src.tar.gz" | sha256sum -c - \
    && export ERL_TOP="/usr/src/otp_src_${OTP_VERSION%%@*}" \
    && mkdir -vp $ERL_TOP \
    && tar -xzf otp-src.tar.gz -C $ERL_TOP --strip-components=1 \
    && rm otp-src.tar.gz \
    && ( cd $ERL_TOP \
      && ./otp_build autoconf \
      && gnuArch="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)" \
      && ./configure --build="$gnuArch" \
      && make -j$(nproc) \
      && make install ) \
    && find /usr/local -name examples | xargs rm -rf \
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -rf $ERL_TOP /var/lib/apt/lists/*

CMD ["erl"]

# extra useful tools here: rebar & rebar3

ENV REBAR_VERSION="2.6.4"

RUN set -xe \
    && REBAR_DOWNLOAD_URL="https://github.com/rebar/rebar/archive/${REBAR_VERSION}.tar.gz" \
    && REBAR_DOWNLOAD_SHA256="577246bafa2eb2b2c3f1d0c157408650446884555bf87901508ce71d5cc0bd07" \
    && mkdir -p /usr/src/rebar-src \
    && curl -fSL -o rebar-src.tar.gz "$REBAR_DOWNLOAD_URL" \
    && echo "$REBAR_DOWNLOAD_SHA256 rebar-src.tar.gz" | sha256sum -c - \
    && tar -xzf rebar-src.tar.gz -C /usr/src/rebar-src --strip-components=1 \
    && rm rebar-src.tar.gz \
    && cd /usr/src/rebar-src \
    && ./bootstrap \
    && install -v ./rebar /usr/local/bin/ \
    && rm -rf /usr/src/rebar-src

RUN set -xe \
    && REBAR3_DOWNLOAD_URL="https://github.com/erlang/rebar3/archive/${REBAR3_VERSION}.tar.gz" \
    && REBAR3_DOWNLOAD_SHA256="e14cdc1f5b7d363a238a9f555f89e878bc4fc836c970571b41b90ee947f91505" \
    && mkdir -p /usr/src/rebar3-src \
    && curl -fSL -o rebar3-src.tar.gz "$REBAR3_DOWNLOAD_URL" \
    && echo "$REBAR3_DOWNLOAD_SHA256 rebar3-src.tar.gz" | sha256sum -c - \
    && tar -xzf rebar3-src.tar.gz -C /usr/src/rebar3-src --strip-components=1 \
    && rm rebar3-src.tar.gz \
    && cd /usr/src/rebar3-src \
    && HOME=$PWD ./bootstrap \
    && install -v ./rebar3 /usr/local/bin/ \
    && rm -rf /usr/src/rebar3-src
