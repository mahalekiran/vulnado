#!/bin/bash
set -e

echo "Building Java application with Maven..."

mvn clean
mvn package

#cp target/*.jar ./build-artifacts/

echo "Build process completed successfully!"