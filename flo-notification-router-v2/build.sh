#!/bin/bash
export JAVA_OPTS="-Xms2048m -Xmx2048m -XX:ReservedCodeCacheSize=128m -XX:MaxMetaspaceSize=256m -Dsbt.version=1.3.2" && sbt package
