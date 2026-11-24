# openprinthq-bambustudio: linuxserver.io's Bambu Studio image, restyled for OpenPrintHQ by
# apps/bambustudio/convert.py and common/restyle.py. Built from the repository's root:
#
#   docker build -f apps/bambustudio/Dockerfile .
#
# The image comes from apps/bambustudio/upstream.env (the release build passes it as build arguments): its
# version tag and the digest that tag must be, so a moved tag fails the build instead of changing what is
# built. Bambu Studio itself is not rebuilt or changed: visuals, and opening files the farm sends.

# The defaults are upstream.env's values, so a plain build builds the pinned image; the tests check they agree.
ARG UPSTREAM_IMAGE=lscr.io/linuxserver/bambustudio
ARG UPSTREAM_VERSION=v02.09.01.70-ls180
ARG UPSTREAM_DIGEST=sha256:8623b30b1a1f569b3704509ef8cbfc6fa4a76876737429f7cfb6eeb9335e3ae9

# The web fonts for the desktop's page (Manrope, Sora, JetBrains Mono), from the fontsource packages.
FROM node:22-alpine AS fonts
ARG FONTSOURCE_VERSION=5.3.0
WORKDIR /pack
RUN npm pack --silent "@fontsource/manrope@${FONTSOURCE_VERSION}" "@fontsource/sora@${FONTSOURCE_VERSION}" \
      "@fontsource/jetbrains-mono@${FONTSOURCE_VERSION}" \
 && mkdir -p /fonts \
 && for f in *.tgz; do mkdir -p "x/$f" && tar -xzf "$f" -C "x/$f"; done \
 && cp x/*manrope*/package/files/manrope-latin-400-normal.woff2 x/*manrope*/package/files/manrope-latin-500-normal.woff2 \
       x/*manrope*/package/files/manrope-latin-600-normal.woff2 x/*manrope*/package/files/manrope-latin-700-normal.woff2 \
       x/*sora*/package/files/sora-latin-500-normal.woff2 \
       x/*jetbrains*/package/files/jetbrains-mono-latin-400-normal.woff2 /fonts/ \
 && cp x/*manrope*/package/LICENSE /fonts/OFL-Manrope.txt \
 && cp x/*sora*/package/LICENSE /fonts/OFL-Sora.txt \
 && cp x/*jetbrains*/package/LICENSE /fonts/OFL-JetBrainsMono.txt

FROM ${UPSTREAM_IMAGE}:${UPSTREAM_VERSION}@${UPSTREAM_DIGEST}
ARG UPSTREAM_VERSION
# Manrope and JetBrains Mono for Bambu Studio's own windows (GTK and labwc), from the distribution (SIL OFL 1.1).
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y fonts-manrope fonts-jetbrains-mono \
 && fc-cache -f \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
COPY common /tmp/ahi/common
COPY apps/bambustudio /tmp/ahi/apps/bambustudio
COPY --from=fonts /fonts /tmp/ahi/common/files/dashboard/fonts
RUN python3 /tmp/ahi/apps/bambustudio/convert.py / && rm -rf /tmp/ahi
COPY LICENSE LICENSES apps/bambustudio/NOTICE /usr/share/doc/openprinthq-bambustudio/
ENV DASHBOARD=artisanhub-dashboard \
    TITLE="Bambu Studio" \
    BROWSER=/usr/local/bin/ahi-open-url
LABEL org.opencontainers.image.title="openprinthq-bambustudio" \
      org.opencontainers.image.source="https://github.com/norjms/openprinthq-desktops" \
      org.opencontainers.image.description="Bambu Studio in a web desktop, in the OpenPrintHQ look, built from linuxserver.io's bambustudio ${UPSTREAM_VERSION}" \
      org.opencontainers.image.licenses="GPL-3.0-only AND AGPL-3.0-only" \
      org.opencontainers.image.version="${UPSTREAM_VERSION}"
