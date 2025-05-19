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
# 如果提供了超级用户凭据，则检查并创建超级用户\n\
if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ]; then\n\
  # 简化判断逻辑，只检查数据目录和数据库文件是否存在\n\
  if [ ! -d "/pb_data" ] || [ ! -f "/pb_data/data.db" ]; then\n\
    echo "数据目录或数据库文件不存在，创建超级用户..."\n\
    /usr/local/bin/pocketbase superuser create "$ADMIN_EMAIL" "$ADMIN_PASSWORD"\n\
  else\n\
    echo "数据目录和数据库文件已存在，跳过创建超级用户..."\n\
  fi\n\
fi\n\
\n\
# 启动PocketBase服务\n\
exec /usr/local/bin/pocketbase serve --http=0.0.0.0:8090 --origins=* --dir=/pb_data\n\
' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
