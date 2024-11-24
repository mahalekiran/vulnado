#!/bin/bash
set -e

echo "Building Java application with Maven..."

mvn clean install
#mvn package

#cp target/*.jar ./build-artifacts/

echo "Build process completed successfully!"