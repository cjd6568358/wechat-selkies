# syntax=docker/dockerfile:1

# Stage 1: xvfb基础镜像（保持不变）
FROM lscr.io/linuxserver/xvfb:arm64v8-ubuntunoble AS xvfb

# Stage 2: 构建优化的基础镜像（移除Docker相关，空间优化）
FROM ghcr.io/linuxserver/baseimage-ubuntu:arm64v8-noble AS baseimage

# set version label
LABEL build_version="Linuxserver.io version"
LABEL maintainer="thelamer"

# env
ENV DISPLAY=:1 \
    PERL5LIB=/usr/local/bin \
    HOME=/config \
    START_DOCKER=true \
    PULSE_RUNTIME_PATH=/defaults \
    SELKIES_INTERPOSER=/usr/lib/selkies_joystick_interposer.so \
    NVIDIA_DRIVER_CAPABILITIES=all \
    DISABLE_ZINK=false \
    DISABLE_DRI3=false \
    TITLE=Selkies

# COPY commands from first Dockerfile
COPY /assets/selkies.tar.gz /tmp/selkies.tar.gz
COPY /assets/libva.deb /tmp/libva/libva.deb
COPY /assets/theme.tar.gz /tmp/theme.tar.gz

# Optimized RUN command - single layer with enhanced cleanup
RUN \
  echo "**** enable locales ****" && \
  sed -i '/locale/d' /etc/dpkg/dpkg.cfg.d/excludes && \
  echo "**** install all deps in one layer (Docker removed) ****" && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    python3-dev \
    breeze-cursor-theme \
    ca-certificates \
    cmake \
    console-data \
    dbus-x11 \
    dunst \
    file \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-noto-core \
    foot \
    fuse-overlayfs \
    g++ \
    gcc \
    git \
    kbd \
    labwc \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libev4 \
    libfontenc1 \
    libfreetype6 \
    libgbm1 \
    libgcrypt20 \
    libgirepository-1.0-1 \
    libgl1-mesa-dri \
    libglu1-mesa \
    libgnutls30 \
    libgtk-3-0 \
    libjpeg-turbo8 \
    libnginx-mod-http-fancyindex \
    libnotify-bin \
    libnss3 \
    libnvidia-egl-wayland1 \
    libopus0 \
    libp11-kit0 \
    libpam0g \
    libtasn1-6 \
    libvulkan1 \
    libwayland-client0 \
    libwayland-cursor0 \
    libwayland-egl1 \
    libwayland-server0 \
    libx11-6 \
    libx264-164 \
    libxau6 \
    libxcb1 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcursor1 \
    libxdmcp6 \
    libxext6 \
    libxfconf-0-3 \
    libxfixes3 \
    libxfont2 \
    libxinerama1 \
    libxkbcommon-dev \
    libxkbcommon-x11-0 \
    libxshmfence1 \
    libxtst6 \
    locales-all \
    make \
    mesa-libgallium \
    mesa-va-drivers \
    mesa-vulkan-drivers \
    nginx \
    openbox \
    openssh-client \
    openssl \
    pciutils \
    procps \
    psmisc \
    pulseaudio \
    pulseaudio-utils \
    python3 \
    python3-venv \
    software-properties-common \
    ssl-cert \
    stterm \
    sudo \
    tar \
    util-linux \
    vulkan-tools \
    wl-clipboard \
    wtype \
    x11-apps \
    x11-common \
    x11-utils \
    x11-xkb-utils \
    x11-xserver-utils \
    xauth \
    xclip \
    xcvt \
    xdg-utils \
    xdotool \
    xfconf \
    xfonts-base \
    xkb-data \
    xsel \
    xserver-common \
    xserver-xorg-core \
    xserver-xorg-video-amdgpu \
    xserver-xorg-video-ati \
    xserver-xorg-video-nouveau \
    xsettingsd \
    xterm \
    xutils \
    xvfb \
    zlib1g \
    zstd \
    libxcb-randr0 \
    libxcb-render0 \
    libxcb-shape0 \
    libxcb-shm0 \
    libxcb-sync1 \
    libxcb-util1 \
    libxcb-xfixes0 \
    libxcb-xinerama0 \
    libx11-xcb1 && \
  echo "**** install selkies ****" && \
  SELKIES_RELEASE=v1.6.2 && \
  cd /tmp && \
  tar xf selkies.tar.gz && \
  cd selkies-* && \
  sed -i '/cryptography/d' pyproject.toml && \
  python3 -m venv --system-site-packages /lsiopy && \
  pip install . && \
  pip install setuptools && \
  echo "**** install selkies interposer ****" && \
  cd addons/js-interposer && \
  gcc -shared -fPIC -ldl -o selkies_joystick_interposer.so joystick_interposer.c && \
  mv selkies_joystick_interposer.so /usr/lib/selkies_joystick_interposer.so && \
  echo "**** install selkies fake udev ****" && \
  cd ../fake-udev && \
  make && \
  mkdir /opt/lib && \
  mv libudev.so.1.0.0-fake /opt/lib/ && \
  echo "**** add icon ****" && \
  mkdir -p /usr/share/selkies/www && \
  echo "**** openbox tweaks ****" && \
  sed -i \
    -e 's/NLIMC/NLMC/g' \
    -e '/debian-menu/d' \
    -e 's|</applications>|  <application class="*"><maximized>yes</maximized></application>\n</applications>|' \
    -e 's|</keyboard>|  <keybind key="C-S-d"><action name="ToggleDecorations"/></keybind>\n</keyboard>|' \
    -e 's|<number>4</number>|<number>1</number>|' \
    /etc/xdg/openbox/rc.xml && \
  sed -i 's/--startup/--replace --startup/g' /usr/bin/openbox-session && \
  echo "**** user perms ****" && \
  sed -e 's/%sudo	ALL=(ALL:ALL) ALL/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' -i /etc/sudoers && \
  echo "abc:abc" | chpasswd && \
  usermod -s /bin/bash abc && \
  usermod -aG sudo abc && \
  echo "**** libva hack ****" && \
  mkdir -p /tmp/libva && \
  cd /tmp/libva && \
  ar x libva.deb && \
  tar xf data.tar.zst && \
  rm -f /usr/lib/aarch64-linux-gnu/libva.so.2* && \
  cp -a usr/lib/aarch64-linux-gnu/libva.so.2* /usr/lib/aarch64-linux-gnu/ && \
  echo "**** locales ****" && \
  localedef -i zh_CN -f UTF-8 zh_CN.UTF-8 && \
  echo "**** theme ****" && \
  tar xzvf /tmp/theme.tar.gz -C /usr/share/themes/Clearlooks/openbox-3/ && \
  echo "**** uninstall build tools ****" && \
  apt-get purge -y --autoremove \
    python3-dev gcc make g++ cmake git software-properties-common && \
  echo "**** enhanced cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /config/.npm \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/* \
    /usr/share/doc/* \
    /usr/share/man/* \
    /usr/share/locale/* !/usr/share/locale/zh_CN* \
    /usr/share/glib-2.0/schemas/*.xml \
    /usr/share/gtk-doc 2>/dev/null || true \
    /usr/lib/python3*/test* /usr/lib/python3*/idlelib* /usr/lib/python3*/ensurepip* \
    /usr/lib/python3.*/dist-packages/*test* && \
  find /usr -name "*.pyc" -delete 2>/dev/null || true && \
  find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true && \
  find /usr/lib -name "*.a" -delete 2>/dev/null || true

# add local files from first Dockerfile
COPY /assets/icon.png /usr/share/selkies/www/icon.png
COPY /assets/favicon.ico /usr/share/selkies/www/favicon.ico
COPY /assets/root /
COPY /assets/buildout /usr/share/selkies
COPY --from=xvfb / /

# Stage 3: Final stage for WeChat
FROM baseimage AS final

# Install WeChat from second Dockerfile
COPY /assets/wechat.deb /tmp/wechat.deb

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 \
        libxkbcommon-x11-0 libxcb1 libxcb-randr0 libxcb-render0 libxcb-shape0 \
        libxcb-shm0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 libxcb-xinerama0 \
        libatk1.0-0 libatk-bridge2.0-0 libc6 libcairo2 libdbus-1-3 \
        libfontconfig1 libgbm1 libgcc1 libgdk-pixbuf2.0-0 libglib2.0-0 \
        libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 \
        libstdc++6 libx11-6 libxcomposite1 libxdamage1 libxext6 libxfixes3 \
        libxi6 libxrandr2 libxrender1 libxss1 libxtst6 libatomic1 \
        libx11-xcb1 stalonetray python3-xlib && \
    dpkg -i /tmp/wechat.deb || apt-get install -f -y && \
    apt-get purge -y --autoremove && \
    apt-get autoclean && \
    rm -rf /tmp/wechat.deb \
        /root/.cache /root/.pip /root/.local \
        /config/.cache /config/.npm \
        /var/lib/apt/lists/* \
        /var/tmp/* /tmp/* \
        /var/log/* \
        /usr/share/doc/* /usr/share/man/* \
        /usr/share/locale/* !/usr/share/locale/zh_CN* \
        /usr/share/glib-2.0/schemas/*.xml \
        /usr/share/gtk-doc 2>/dev/null || true \
        /usr/lib/python3*/test* /usr/lib/python3*/idlelib* /usr/lib/python3*/ensurepip* \
        /usr/lib/python3.*/dist-packages/*test* && \
    find /usr -name "*.pyc" -delete 2>/dev/null || true && \
    find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/lib -name "*.a" -delete 2>/dev/null || true && \
    sed -i '/<dock>/,/<\/dock>/s/<noStrut>no<\/noStrut>/<noStrut>yes<\/noStrut>/' /etc/xdg/openbox/rc.xml && \
    cp /usr/share/icons/hicolor/128x128/apps/wechat.png /usr/share/selkies/www/icon.png && \
    mkdir -p /var/log/nginx && chmod 755 /var/log/nginx

# set app name
ENV TITLE="WeChat-Selkies"
ENV TZ="Asia/Shanghai"
ENV LC_ALL="zh_CN.UTF-8"
ENV AUTO_START_WECHAT="true"

# add local files from second Dockerfile
COPY /assets/root /

# ports and volumes
EXPOSE 3000 3001
VOLUME /config
