#!/bin/ash

AUTHORIZED_KEYS="{{ ssh_auth_keys_gzip_base64 }}"
WS_TOKEN="{{ ws_server_token_gzip_base64 }}"

error() {
  echo "ERROR: $@" >&2
}

configure_authorized_ssh_keys() {
  echo "${AUTHORIZED_KEYS}" | xargs fw_setenv auth-ssh-keys
  if [ "$(fw_printenv -n auth-ssh-keys)" != "${AUTHORIZED_KEYS}" ]; then
    return 1
  fi

  ash /lib/presysinit/presysinit.d/openssh.presysinit.sh
  if [ "$?" -ne 0 ]; then
    return 1
  fi
}

configure_wifi() {
  fw_setenv apmode 1

  res=$(dbus-send --print-reply --system --type=method_call \
    --dest=com.flotechnologies.framework \
    /com/flotechnologies/framework \
    com.flotechnologies.framework.network.SetApModeAlwaysEnabled \
    string:"{\"Enabled\": true}")
  if ! echo $res | grep -Fq '"Result":"OK"'; then
    return 1
  fi
}

configure_ws_server() {
  if ! fw_setenv ws-cert; then
    return 1
  fi

  fw_setenv ws-token "${WS_TOKEN}"
  if [ "$(fw_printenv -n ws-token)" != "${WS_TOKEN}" ]; then
    return 1
  fi
}

echo "* Configuring Wi-Fi..."
if ! configure_wifi; then
  error "Cannot configure Wi-Fi properly"
  exit 1
fi

echo "* Clearing MQTT client config..."
if ! (fw_setenv mqtt-host && fw_setenv mqtt-port); then
  error "Cannot clear MQTT client config properly"
  exit 1
fi

echo "* Configuring WebSocket server..."
if ! configure_ws_server; then
  error "Cannot configure WebSocket server properly"
  exit 1
fi

echo "* Configuring authorized SSH keys..."
if ! configure_authorized_ssh_keys; then
  error "Cannot configure authorized SSH keys properly"
  exit 1
fi
