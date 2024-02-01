#!/usr/bin/with-contenv bashio
set -e
bashio::log.debug "Building ngrok.yml..."
configPath="/ngrok-config/ngrok.yml"
mkdir -p /ngrok-config
echo "log: stdout" > $configPath
bashio::log.debug "Web interface port: $(bashio::addon.port 4040)"
echo "version: 2" >> $configPath

USE_WEB="0"
WEB_HOST="127.0.0.1"
WEB_PORT="4040"
if bashio::var.has_value "$(bashio::addon.port 4040)"; then
  WEB_PORT="$(bashio::addon.port 4040)"
  USE_WEB="1"
fi
if bashio::var.has_value "$(bashio::config 'web_host')"; then
  WEB_HOST="$(bashio::config 'web_host')"
  USE_WEB="1"
fi
if bashio::var.has_value "$(bashio::config 'web_allow_hosts')"; then
  echo "web_allow_hosts:" >> $configPath
  WEB_ALLOW_HOSTS="$(bashio::config 'web_allow_hosts')"
  for i in ${WEB_ALLOW_HOSTS//,/ }
  do
    echo "  - $i" >> $configPath
  done
fi

if [ "$USE_WEB" -eq "1" ]; then
  echo "web_addr: $WEB_HOST:$WEB_PORT" >> $configPath
fi

if bashio::var.has_value "$(bashio::config 'log_level')"; then
  echo "log_level: $(bashio::config 'log_level')" >> $configPath
fi
if bashio::var.has_value "$(bashio::config 'auth_token')"; then
  echo "authtoken: $(bashio::config 'auth_token')" >> $configPath
fi
if bashio::var.has_value "$(bashio::config 'region')"; then
  echo "region: $(bashio::config 'region')" >> $configPath
else
  echo "No region defined, default region is US."
fi

bashio::log.debug "Tunnels: $(bashio::config "tunnels|keys")"
bashio::log.debug "Tunnels: $(bashio::config "tunnels")"

echo "tunnels:" >> $configPath
for id in $(bashio::config "tunnels|keys"); do
  name=$(bashio::config "tunnels[${id}].name")
  echo "  $name:" >> $configPath
  proto=$(bashio::config "tunnels[${id}].proto")
  if [[ $proto != "null" ]]; then
    echo "    proto: $proto" >> $configPath
  fi
  addr=$(bashio::config "tunnels[${id}].addr")
  if [[ $addr != "null" ]]; then
    if [[ $addr =~ ^([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])$ ]]; then
      echo "    addr: 172.30.32.1:$addr" >> $configPath
    else
      echo "    addr: $addr" >> $configPath
    fi
  fi
  inspect=$(bashio::config "tunnels[${id}].inspect")
  if [[ $inspect != "null" ]]; then
    echo "    inspect: $inspect" >> $configPath
  fi
  #auth=$(bashio::config "tunnels[${id}].auth")
  #if [[ $auth != "null" ]]; then
  #  echo "    auth: $auth" >> $configPath
  #fi
  host_header=$(bashio::config "tunnels[${id}].host_header")
  if [[ $host_header != "null" ]]; then
    echo "    host_header: $host_header" >> $configPath
  fi
  bind_tls=$(bashio::config "tunnels[${id}].bind_tls")
  if [[ $bind_tls != "null" ]]; then
    echo "    bind_tls: $bind_tls" >> $configPath
  fi
  subdomain=$(bashio::config "tunnels[${id}].subdomain")
  if [[ $subdomain != "null" ]]; then
    echo "    subdomain: $subdomain" >> $configPath
  fi
  hostname=$(bashio::config "tunnels[${id}].hostname")
  if [[ $hostname != "null" ]]; then
    echo "    hostname: $hostname" >> $configPath
  fi
  crt=$(bashio::config "tunnels[${id}].crt")
  if [[ $crt != "null" ]]; then
    echo "    crt: $crt" >> $configPath
  fi
  key=$(bashio::config "tunnels[${id}].key")
  if [[ $key != "null" ]]; then
    echo "    key: $key" >> $configPath
  fi
  client_cas=$(bashio::config "tunnels[${id}].client_cas")
  if [[ $client_cas != "null" ]]; then
    echo "    client_cas: $client_cas" >> $configPath
  fi
  remote_addr=$(bashio::config "tunnels[${id}].remote_addr")
  if [[ $remote_addr != "null" ]]; then
    echo "    remote_addr: $remote_addr" >> $configPath
  fi
  metadata=$(bashio::config "tunnels[${id}].metadata")
  if [[ $metadata != "null" ]]; then
    echo "    metadata: $metadata" >> $configPath
  fi
  insecure=$(bashio::config "tunnels[${id}].insecure")
  if [[ $insecure != "null" ]]; then
    echo "    insecure: $insecure" >> $configPath
  fi
  
done
configfile=$(cat $configPath)
cat $configPath
bashio::log.debug "Config file: \n${configfile}"
bashio::log.info "Starting ngrok..."
ngrok start --config $configPath --all
