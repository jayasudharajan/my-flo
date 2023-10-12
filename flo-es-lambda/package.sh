#!/usr/bin/bash

if [ -d "build" ]; then
	rm -rv build
fi

mkdir build

cp package.json build/
cp -r src/ build/

cd build

npm install --production && \

curl -u${BINTRAY_USER}:${BINTRAY_KEY} https://api.bintray.com/npm/flo/npm/auth -o ~/.npmrc && \
npm install --save flo-nodejs-encryption --registry https://api.bintray.com/npm/flo/npm && \
rm -f ~/.npmrc && \
zip -r es-lambda.zip * &&\
cd .. 

mv build/es-lambda.zip .


