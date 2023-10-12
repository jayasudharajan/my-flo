#!/usr/bin/env bash

DOCS_DIR=src/docs;
API_DIR=src;

mkdir ${DOCS_DIR};

echo "generating swagger files for in ${DOCS_DIR} directory";

# https://github.com/swaggo/swag/releases
~/bin/swaggo/swag init -d ${API_DIR} -o ${DOCS_DIR};

echo "Finished generating swagger files for in ${DOCS_DIR} directory";
echo "Done"
