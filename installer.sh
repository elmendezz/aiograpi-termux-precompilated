#!/usr/bin/env bash
set -e

RELEASE_TAG="build-2026.08.01-020231"
REPO="elmendezz/aiograpi-termux-precompilated"
TEMP_DIR="$(mktemp -d -t aiograpi-wheels-XXXXXX)"

echo "🚀 Iniciando instalacion rapida de aiograpi para dispositivos modestos..."
echo "📦 Descargando wheels desde el repo: $REPO ($RELEASE_TAG)"


if ! command -v curl &> /dev/null || ! command -v jq &> /dev/null; then
    echo "⚙️ Instalando curl y jq..."
    pkg install curl jq -y
fi

WHEEL_URLS=$(curl -s "https://api.github.com/repos/$REPO/releases/tags/$RELEASE_TAG" | jq -r '.assets[].browser_download_url')

if [ -z "$WHEEL_URLS" ]; then
    echo "❌ Error: No se encontraron wheels (.whl) en la release $RELEASE_TAG."
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "📥 Descargando paquetes en directorio temporal..."
cd "$TEMP_DIR"

for url in $WHEEL_URLS; do
    echo "  -> Jalando: $(basename "$url")"
    curl -sL -O "$url"
done


echo "🔧 Ajustando etiquetas de plataforma para compatibilidad universal..."

API_LEVEL=$(getprop ro.build.version.sdk 2>/dev/null || echo "24")

for f in *.whl; do
  if [ -f "$f" ]; then

    newname=$(echo "$f" | sed -E "s/android_[0-9]+/android_${API_LEVEL}/g")
    if [ "$f" != "$newname" ]; then
      mv "$f" "$newname"
    fi
  fi
done


echo "⚡ Instalando aiograpi y todas sus dependencias sin compilar..."
pip install --no-index --find-links="$TEMP_DIR" "$TEMP_DIR"/*.whl


echo "🧹 Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"

echo "✅ ¡Listo mi hermano! aiograpi quedo instalado y funcionando al 100."
