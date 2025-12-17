#!/bin/bash
# ==========================================
# cf-ip-update-distribute.sh
# 自动获取优选 IP 并分配到子域名列表，每个子域名分配不同 IP
# ==========================================

# ------------------------
# 用户配置
# ------------------------
CF_API_TOKEN="***************"
ZONE_ID="***************"
TTL=60
PROXIED=false
#IP_API="https://ip.164746.xyz/ipTop10.html"
IP_API="https://ip.164746.xyz/ipTop10.html"

# 子域名列表，可以新增子域名
SUBDOMAINS=("test1.com" "test2.com" "test3.com")

# 每个子域名最多挂几个 IP
MAX_IPS_PER_DOMAIN=3

# ------------------------
# 获取 IP
# ------------------------
echo "获取优选 IP ..."
mapfile -t IPS < <(curl -s "$IP_API" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

if [ ${#IPS[@]} -eq 0 ]; then
  echo "[ERROR] 未获取到 IP，退出"
  exit 1
fi

echo "获取到 IP 列表: ${IPS[*]}"

# ------------------------
# 循环处理每个子域名
# ------------------------
for i in "${!SUBDOMAINS[@]}"; do
  RECORD_NAME="${SUBDOMAINS[$i]}"
  echo "处理子域名: $RECORD_NAME"

  # 删除旧记录
  EXIST_IDS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$RECORD_NAME" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    | grep -o '"id":"[^"]*"' | awk -F':' '{print $2}' | tr -d '"')

  if [ -n "$EXIST_IDS" ]; then
    echo "删除旧 DNS 记录 ..."
    for id in $EXIST_IDS; do
      curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$id" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json"
    done
  fi

  # 添加新记录，每个子域名挂 MAX_IPS_PER_DOMAIN 个 IP
  for j in $(seq 0 $((MAX_IPS_PER_DOMAIN-1))); do
    IP="${IPS[$(( (i*MAX_IPS_PER_DOMAIN + j) % ${#IPS[@]} ))]}"  # 循环使用 IP
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      --data "{
        \"type\": \"A\",
        \"name\": \"$RECORD_NAME\",
        \"content\": \"$IP\",
        \"ttl\": $TTL,
        \"proxied\": $PROXIED
      }"
    echo "子域名 $RECORD_NAME 添加 IP: $IP"
  done
done

echo "全部子域名多 IP 分配完成"
