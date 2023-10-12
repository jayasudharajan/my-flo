#!/usr/bin/env bash

DOCS_DIR=docs;
API_DIR=.;

if [ -d ${DOCS_DIR} ]; then
 echo "removing ${DOCS_DIR} directory";
 rm -R -f ${DOCS_DIR};
fi

mkdir ${DOCS_DIR};

echo "generating swagger files for in ${DOCS_DIR} directory";

~/swag_1.5.0_Darwin_x86_64/swag init -d ${API_DIR} -o ${DOCS_DIR};