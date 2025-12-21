# WeChat for Linux using Selkies baseimage
FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble as builder

# Metadata labels
LABEL org.opencontainers.image.title="WeChat Selkies"
LABEL org.opencontainers.image.description="WeChat Linux client in browser via Selkies WebRTC"
LABEL org.opencontainers.image.authors="nickrunning"
LABEL org.opencontainers.image.source="https://github.com/nickrunning/wechat-selkies"
LABEL org.opencontainers.image.documentation="https://github.com/nickrunning/wechat-selkies#readme"
LABEL org.opencontainers.image.vendor="WeChat Selkies Project"
LABEL org.opencontainers.image.licenses="GPL-3.0-only"

# Build arguments for multi-arch support
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "🏗️ Building WeChat-Selkies on $BUILDPLATFORM, targeting $TARGETPLATFORM"

# Download WeChat in builder stage (minimal layer)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl ca-certificates && \
    case "$TARGETPLATFORM" in \
        "linux/amd64") \
            WECHAT_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb" ;; \
        "linux/arm64") \
            WECHAT_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.deb" ;; \
        *) echo "Unsupported platform"; exit 1 ;; \
    esac && \
    curl -fsSL -o /tmp/wechat.deb "$WECHAT_URL" && \
    apt-get purge -y --autoremove curl ca-certificates && \
    rm -rf /var/lib/apt/lists/* /var/tmp/*

# Final stage - ultra-minimal
FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "🏗️ Building WeChat-Selkies on $BUILDPLATFORM, targeting $TARGETPLATFORM"

# Copy WeChat from builder
COPY --from=builder /tmp/wechat.deb /tmp/wechat.deb

# Install ONLY essential runtime dependencies + WeChat in ONE layer (UNCHANGED)
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

# add local files
COPY /root /