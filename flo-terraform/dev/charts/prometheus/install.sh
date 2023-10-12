#!/usr/bin/env bash
function install_kube_svc_ctl() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        KUBE_SVC_CTL_PLATFORM=linux
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        KUBE_SVC_CTL_PLATFORM=darwin
    elif [[ "$OSTYPE" == "linux-musl"* ]]; then
        KUBE_SVC_CTL_PLATFORM=alpine
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo "Unsupported platform!"
        exit 1
    elif [[ "$OSTYPE" == "msys" ]]; then
        echo "Unsupported platform!"
        exit 1
    elif [[ "$OSTYPE" == "win32" ]]; then
        echo "Unsupported platform!"
        exit 1
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo "Unsupported platform!"
        exit 1
    else
        echo "Unsupported platform!"
        exit 1
    fi

    if [[ ! -f kube-svc-ctl ]]; then
        wget https://nexus.flotech.co/repository/tools/kube-svc-ctl/$KUBE_SVC_CTL_PLATFORM/kube-svc-ctl -O kube-svc-ctl
        chmod +x kube-svc-ctl
    fi
}
install_kube_svc_ctl
./kube-svc-ctl generate-secret-manifest > registry-secret.yaml
kubectl apply -f registry-secret.yaml --namespace prometheus
python3 install.py