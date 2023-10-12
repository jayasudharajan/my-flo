FROM golang:1.20.5-bullseye

ARG CI_COMMIT_SHA
ARG CI_COMMIT_MESSAGE
ARG COMMIT_TIME

RUN cd /tmp \
    && git clone --branch v1.3.0 https://github.com/edenhill/librdkafka.git \
    && cd /tmp/librdkafka \
    && ./configure --prefix /usr \
    && make \
    && make install \
    && rm -rf /tmp/librdkafka

ADD ./src /src

WORKDIR /src

RUN cd /src \
    && ls -lh \
    && mkdir -pv /app /app/creds \
    && CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -a -o /app/flo-firewriter -ldflags "-X main.commitSha=${CI_COMMIT_SHA} -X main.commitTime=${COMMIT_TIME} -X main.commitName=$( echo ${CI_COMMIT_MESSAGE} | sed 's/ /_/g')" .

WORKDIR /app
ENTRYPOINT ["/app/flo-firewriter"]
