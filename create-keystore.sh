#!/bin/bash

set -e

KEYSTORE_DIR=certs
KEYSTORE_FILE=$KEYSTORE_DIR/keystore.p12
KEYSTORE_PASS=changeit

# Tạo thư mục chứa cert nếu chưa có
mkdir -p "$KEYSTORE_DIR"

echo "🛡️  Generating self-signed certificate and keystore..."

keytool -genkeypair \
  -alias tomcat \
  -keyalg RSA \
  -keysize 2048 \
  -validity 365 \
  -storetype PKCS12 \
  -keystore "$KEYSTORE_FILE" \
  -storepass "$KEYSTORE_PASS" \
  -dname "CN=localhost, OU=Dev, O=Company, L=City, S=State, C=VN"

echo "✅ Keystore generated at $KEYSTORE_FILE"
echo "🔑 Keystore password: $KEYSTORE_PASS"