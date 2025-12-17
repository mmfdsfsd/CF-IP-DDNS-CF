使用说明

配置：

CF_API_TOKEN、ZONE_ID

SUBDOMAINS → 你要更新的子域名

MAX_IPS_PER_DOMAIN → 每个子域名挂几个 IP

执行：

<code>chmod +x cf-ip-update-multi-a.sh</code><br>
<code>./cf-ip-update-multi-a.sh</code>


可加入 cron 自动更新：

<code>*/10 * * * * /root/cf-ip-update-multi-a.sh >> /var/log/cf-ip-update.log 2>&1</code>

