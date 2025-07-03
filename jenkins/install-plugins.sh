#!/bin/bash

set -e

PLUGINS_FILE="/usr/share/jenkins/ref/plugins.txt"

if [ -f "$PLUGINS_FILE" ]; then
  echo "Instalando plugins desde $PLUGINS_FILE..."
  jenkins-plugin-cli --plugin-file "$PLUGINS_FILE"
  echo "✅ Plugins instalados correctamente."
else
  echo "❌ No se encontró el archivo $PLUGINS_FILE"
  exit 1
fi
