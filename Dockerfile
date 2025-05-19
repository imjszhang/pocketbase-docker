FROM alpine:3 as downloader

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG VERSION

ENV BUILDX_ARCH="${TARGETOS:-linux}_${TARGETARCH:-amd64}${TARGETVARIANT}"

RUN wget https://github.com/pocketbase/pocketbase/releases/download/v${VERSION}/pocketbase_${VERSION}_${BUILDX_ARCH}.zip \
    && unzip pocketbase_${VERSION}_${BUILDX_ARCH}.zip \
    && chmod +x /pocketbase

FROM alpine:3
RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*

EXPOSE 8090

COPY --from=downloader /pocketbase /usr/local/bin/pocketbase

# 创建启动脚本
RUN echo '#!/bin/sh\n\
# 如果提供了超级用户凭据，则创建超级用户\n\
if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ]; then\n\
  /usr/local/bin/pocketbase superuser create "$ADMIN_EMAIL" "$ADMIN_PASSWORD"\n\
fi\n\
\n\
# 启动PocketBase服务\n\
exec /usr/local/bin/pocketbase serve --http=0.0.0.0:8090 --dir=/pb_data\n\
' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
