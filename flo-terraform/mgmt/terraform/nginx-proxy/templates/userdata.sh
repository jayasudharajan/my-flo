#!/bin/bash

set -ex

export AWS_REGION=us-west-2
export AWS_DEFAULT_REGION="${AWS_REGION}"

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install awscli jq nginx libnginx-mod-http-headers-more-filter libnginx-mod-http-upstream-fair -y
sudo wget https://raw.githubusercontent.com/nginxinc/NGINX-Demos/master/nginx-hello/index.html --output-document /usr/share/nginx/html/index.html
sudo wget https://raw.githubusercontent.com/nginxinc/NGINX-Demos/master/nginx-hello/hello.conf --output-document /etc/nginx/sites-enabled/default

# SSL certificates
aws ssm get-parameter \
  --with-decryption \
  --name /managed/terraform/lte-proxy/ssl/cert/multidomain_flotech_co_cert \
  | jq -r '.Parameter.Value' > /etc/ssl/certs/multidomain_flotech_co_ssl-bundle.crt
aws ssm get-parameter \
  --with-decryption \
  --name /managed/terraform/lte-proxy/ssl/cert/multidomain_flotech_co_ca_bundle \
  | jq -r '.Parameter.Value' >> /etc/ssl/certs/multidomain_flotech_co_ssl-bundle.crt
aws ssm get-parameter \
  --with-decryption \
  --name /managed/terraform/lte-proxy/ssl/cert/multidomain_flotech_co_key \
  | jq -r '.Parameter.Value' > /etc/ssl/private/multidomain_flotech_co.key
aws ssm get-parameter \
  --with-decryption \
  --name /managed/terraform/lte-proxy/ssl/cert/multidomain_meetflo_com_cert \
  | jq -r '.Parameter.Value' > /etc/ssl/certs/multidomain_meetflo_com_ssl-bundle.crt
aws ssm get-parameter \
  --with-decryption \
  --name /managed/terraform/lte-proxy/ssl/cert/multidomain_meetflo_com_ca_bundle \
  | jq -r '.Parameter.Value' >> /etc/ssl/certs/multidomain_meetflo_com_ssl-bundle.crt
aws ssm get-parameter \
  --with-decryption \
  --name /managed/terraform/lte-proxy/ssl/cert/multidomain_meetflo_com_key \
  | jq -r '.Parameter.Value' > /etc/ssl/private/multidomain_meetflo_com.key


# nginx proxy configurations

mkdir -pv /etc/nginx/stream_conf.d

cat <<-'EOF' >> /etc/nginx/nginx.conf

# MQTT Streams
stream {
    include stream_conf.d/*.conf;
}

EOF

cat <<-'EOF' > /etc/nginx/stream_conf.d/api-bulk.conf
log_format stream '$remote_addr [$time_local] $protocol $status $bytes_received '
                '$bytes_sent $upstream_addr';

upstream bulk_443 {
  server  api-bulk.meetflo.com:443;
  zone    tcp_mem 64k;
}

server {
  listen                8443;
  proxy_pass            bulk_443;
  proxy_connect_timeout 30s;
  # proxy_responses 0;

  access_log /var/log/nginx/api-bulk.meetflo.com.log stream;
  error_log  /var/log/nginx/error.log; # Health check notifications
}
EOF

cat <<-'EOF' > /etc/nginx/stream_conf.d/mender-store.conf
log_format s3 '$remote_addr [$time_local] $protocol $status $bytes_received '
                '$bytes_sent $upstream_addr';

upstream s3_443 {
  server  flosecurecloud-mender-store.s3.us-west-2.amazonaws.com:443;
  zone    tcp_mem 64k;
}

server {
  listen                9443;
  proxy_pass            s3_443;
  proxy_connect_timeout 30s;
  # proxy_responses 0;

  access_log /var/log/nginx/flosecurecloud-mender-store.s3.us-west-2.amazonaws.com.log s3;
  error_log  /var/log/nginx/error.log; # Health check notifications
}
EOF

cat <<-'EOF' > /etc/nginx/stream_conf.d/odt.conf
log_format openvpn '$remote_addr [$time_local] $protocol $status $bytes_received '
                '$bytes_sent $upstream_addr';

# 1194

upstream odt_943 {
  server  odt.flotech.co:943;
  zone    tcp_mem 64k;
}

upstream odt_1194 {
  server  odt.flotech.co:1194;
  zone    tcp_mem 64k;
}

server {
  listen                943;
  proxy_pass            odt_943;
  proxy_connect_timeout 30s;

  access_log /var/log/nginx/odt_access.log openvpn;
  error_log  /var/log/nginx/odt_error.log; # Health check notifications
}

server {
  listen                1194 udp reuseport;
  proxy_pass            odt_1194;
  proxy_connect_timeout 30s;
  # proxy_responses 0;

  access_log /var/log/nginx/odt_access.log openvpn;
  error_log  /var/log/nginx/odt_error.log; # Health check notifications
}
EOF

cat <<-'EOF' > /etc/nginx/stream_conf.d/mqtt.conf
log_format mqtt '$remote_addr [$time_local] $protocol $status $bytes_received '
                '$bytes_sent $upstream_addr';

# 8000, 8001, 8883, 8884, 8885

upstream hivemq_8001 {
  server  mqtt.flosecurecloud.com:8001;
  zone    tcp_mem 64k;
}

upstream hivemq_8883 {
  server  mqtt.flosecurecloud.com:8883;
  zone    tcp_mem 64k;
}

upstream hivemq_8884 {
  server  mqtt.flosecurecloud.com:8884;
  zone    tcp_mem 64k;
}

upstream hivemq_8885 {
  server  mqtt.flosecurecloud.com:8885;
  zone    tcp_mem 64k;
}

server {
  listen                8001;
  proxy_pass            hivemq_8001;
  proxy_connect_timeout 5s;
  # health_check          match=mqtt_conn;

  access_log /var/log/nginx/mqtt_access.log mqtt;
  error_log  /var/log/nginx/mqtt_error.log; # Health check notifications
}

server {
  listen                8883;
  proxy_pass            hivemq_8883;
  proxy_connect_timeout 5s;
  # health_check          match=mqtt_conn;

  access_log /var/log/nginx/mqtt_access.log mqtt;
  error_log  /var/log/nginx/mqtt_error.log; # Health check notifications
}

server {
  listen                8884;
  proxy_pass            hivemq_8884;
  proxy_connect_timeout 5s;
  # health_check          match=mqtt_conn;

  access_log /var/log/nginx/mqtt_access.log mqtt;
  error_log  /var/log/nginx/mqtt_error.log; # Health check notifications
}
EOF

cat <<-'EOF' > /etc/nginx/sites-enabled/default
map $http_upgrade $connection_upgrade {
	default upgrade;
	'' close;
}

server {
    listen 80;
    server_name mqtt.flosecurecloud.com;

    location / {
        proxy_pass       http://mqtt.flosecurecloud.com;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass_request_headers on;
    }

    access_log  /var/log/nginx/mqtt.flosecurecloud.com.access.log;
    error_log   /var/log/nginx/error.log;
}

server {
    listen 8000;
    server_name mqtt.floseculecloud.com;

    location / {
        proxy_pass       http://mqtt.flosecurecloud.com:8000;
        proxy_http_version 1.1;
        proxy_pass_request_headers on;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    access_log  /var/log/nginx/mqtt.flosecurecloud.com.access.log;
    error_log   /var/log/nginx/error.log;

}

server {
    listen 8081 ssl;
    server_name mqtt.floseculecloud.com;

    ssl_certificate     /etc/ssl/certs/multidomain_meetflo_com_ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/private/multidomain_meetflo_com.key;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass       https://mqtt.flosecurecloud.com:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass_request_headers on;
    }

    access_log  /var/log/nginx/mqtt.flosecurecloud.com.access.log;
    error_log   /var/log/nginx/error.log;

}

server {
    listen 443 ssl;
    server_name mender.flotech.co;

    ssl_certificate     /etc/ssl/certs/multidomain_flotech_co_ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/private/multidomain_flotech_co.key;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass       https://mender.flotech.co;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass_request_headers on;
    }

    access_log  /var/log/nginx/mender.flotech.co.access.log;
    error_log   /var/log/nginx/error.log;

}

server {
    listen 443 ssl;
    server_name odt.flotech.co;

    ssl_certificate     /etc/ssl/certs/multidomain_flotech_co_ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/private/multidomain_flotech_co.key;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass       https://odt.flotech.co;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass_request_headers on;
    }

    access_log  /var/log/nginx/odt.flotech.co.access.log;
    error_log   /var/log/nginx/error.log;

}

server {
    listen 80;
    server_name api-gw.meetflo.com;

    location / {
        proxy_pass       http://api-gw.meetflo.com;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass_request_headers on;
    }

    access_log  /var/log/nginx/api-gw.meetflo.com.access.log;
    error_log   /var/log/nginx/error.log;
}

server {
    listen 443 ssl;
    server_name api-gw.meetflo.com;

    ssl_certificate     /etc/ssl/certs/multidomain_meetflo_com_ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/private/multidomain_meetflo_com.key;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass       https://api-gw.meetflo.com;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass_request_headers on;
    }

    access_log  /var/log/nginx/api-gw.meetflo.com.access.log;
    error_log   /var/log/nginx/error.log;

}

server {
    listen 80;
    server_name api.meetflo.com;

    location / {
        proxy_pass       http://api.meetflo.com;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass_request_headers on;
    }

    access_log  /var/log/nginx/api.meetflo.com.access.log;
    error_log   /var/log/nginx/error.log;
}

server {
    listen 443 ssl;
    server_name api.meetflo.com;

    ssl_certificate     /etc/ssl/certs/multidomain_meetflo_com_ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/private/multidomain_meetflo_com.key;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass       https://api.meetflo.com;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass_request_headers on;
    }

    access_log  /var/log/nginx/api.meetflo.com.access.log;
    error_log   /var/log/nginx/error.log;

}

# log_format postdata $request_body;
log_format postdata escape=none '[$time_local] $request \n $request_body';

server {
    listen 443 ssl;
    server_name api-bulk.meetflo.com;

    ssl_certificate     /etc/ssl/certs/multidomain_meetflo_com_ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/private/multidomain_meetflo_com.key;
    ssl_prefer_server_ciphers on;

    underscores_in_headers on;

    location / {
        # proxy_pass       https://api-bulk.meetflo.com:443;
        proxy_pass https://cplq3smmy7.execute-api.us-west-2.amazonaws.com/prod/;
        proxy_pass_header Content-Type;
        proxy_pass_header Expires;
        proxy_pass_header Vary;
        proxy_pass_header macAddress;
        proxy_pass_header x-data-startdate;
        proxy_pass_header x-data-version;
        proxy_pass_header x-flo-signature;
        proxy_pass_header x-flo-signature-type;
        proxy_pass_header x-flo-device-id;
        proxy_set_header Host $proxy_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass_request_body on;
        proxy_pass_request_headers on;
        proxy_ssl_server_name on;
        proxy_buffering off;
        proxy_http_version 1.1;
    }

    access_log  /var/log/nginx/api-bulk.meetflo.com.access.log;
    access_log  /var/log/nginx/api-bulk.meetflo.com.post.log postdata;
    error_log   /var/log/nginx/error.log;

}
EOF

/usr/sbin/nginx -t
systemctl restart nginx
