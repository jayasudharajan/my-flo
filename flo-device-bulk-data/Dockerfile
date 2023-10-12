FROM node:12-alpine

RUN apk update

RUN apk add --no-cache \
    coreutils \
    curl \
    bash

# Install Serverless Framework
RUN npm config set unsafe-perm true  
RUN npm install -g serverless

WORKDIR /app
COPY . .

RUN sls --version && npm -v && node -v
RUN npm install

CMD ["./sls-offline.sh"]

EXPOSE 3000