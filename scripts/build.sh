#!/bin/bash
set -e

echo "Building Java application with Maven..."

mvn -v
java -version
mvn clean install
#mvn package

#cp target/*.jar ./build-artifacts/

echo "Build process completed successfully!"