#!/bin/sh

# 如果提供了超级用户凭据，则检查并创建超级用户
if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ]; then
  # 简化判断逻辑，只检查数据目录和数据库文件是否存在
  if [ ! -d "/pb_data" ] || [ ! -f "/pb_data/data.db" ]; then
    echo "数据目录或数据库文件不存在，创建超级用户..."
    /usr/local/bin/pocketbase superuser create "$ADMIN_EMAIL" "$ADMIN_PASSWORD"
  else
    echo "数据目录和数据库文件已存在，跳过创建超级用户..."
  fi
fi

# 启动PocketBase服务
exec /usr/local/bin/pocketbase serve --http=0.0.0.0:8090 --origins=* --dir=./pb_data 