#!/bin/bash

# ==============================================================
# Paper Minecraft Server download and startup script
# Version: 1.21.11 (build 116)
# ==============================================================

set -e

# --- Version and URL (your direct link) ---
SERVER_JAR="paper-1.21.11-116.jar"
API_URL="https://fill-data.papermc.io/v1/objects/e708e8c132dc143ffd73528cccb9532e2eb17628b1a0eee74469bf466c7003f8/paper-1.21.11-116.jar"

# --- Java ---
JAVA_CMD="java"
JDK_DIR="./jdk"

check_java_version() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        return 1
    fi
    local ver
    ver=$("$cmd" -version 2>&1 | head -1 | cut -d '"' -f2 | sed 's/^1\.//' | cut -d '.' -f1)
    [ "$ver" -ge 21 ]
}

# --- Local Java ---
if [ -f "$JDK_DIR/bin/java" ]; then
    echo "ℹ️  Found local Java in $JDK_DIR"
    if check_java_version "$JDK_DIR/bin/java"; then
        JAVA_CMD="$JDK_DIR/bin/java"
        echo "✅ Using local Java 21+"
    else
        echo "⚠️  Local Java is outdated. Removing it."
        rm -rf "$JDK_DIR"
    fi
fi

# --- System Java or download ---
if [ "$JAVA_CMD" = "java" ]; then
    if check_java_version "java"; then
        echo "✅ Found system Java 21+"
    else
        echo "⬇️  Downloading Java 21..."
        JDK_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.2%2B13/OpenJDK21U-jdk_x64_linux_hotspot_21.0.2_13.tar.gz"
        JDK_TAR="OpenJDK21U-jdk_x64_linux_hotspot_21.0.2_13.tar.gz"
        curl -# -L -o "$JDK_TAR" "$JDK_URL" || { echo "❌ Failed to download Java"; exit 1; }
        mkdir -p "$JDK_DIR"
        tar -xzf "$JDK_TAR" -C "$JDK_DIR" --strip-components=1 || { echo "❌ Failed to extract Java"; exit 1; }
        rm -f "$JDK_TAR"
        [ -f "$JDK_DIR/bin/java" ] || { echo "❌ Java not found after extraction"; exit 1; }
        JAVA_CMD="$JDK_DIR/bin/java"
        echo "✅ Java 21 installed locally."
    fi
fi

# --- Final Java check ---
[ -x "$JAVA_CMD" ] || { echo "❌ Error: Java not found ($JAVA_CMD)"; exit 1; }
echo "🔍 Using Java: $("$JAVA_CMD" -version 2>&1 | head -1)"

# --- JAR validation (ZIP signature) ---
is_jar_valid() {
    local f="$1"
    [ -f "$f" ] || return 1
    local hex
    hex=$(dd if="$f" bs=1 count=4 2>/dev/null | od -An -tx1 | tr -d ' ')
    [ "$hex" = "504b0304" ]
}

# --- Download Paper with response check ---
download_paper() {
    echo "⬇️  Downloading Paper 1.21.11 (build 116)..."
    
    http_code=$(curl -s -L -w "%{http_code}" -o "$SERVER_JAR" "$API_URL")
    
    if [ "$http_code" -ne 200 ]; then
        echo "❌ HTTP error $http_code."
        if [ -f "$SERVER_JAR" ]; then
            echo "   Response content (first 5 lines):"
            head -n 5 "$SERVER_JAR"
        fi
        rm -f "$SERVER_JAR"
        return 1
    fi

    if is_jar_valid "$SERVER_JAR"; then
        echo "✅ Download successful, JAR is valid."
        return 0
    else
        echo "❌ Downloaded file is corrupted or not a JAR."
        rm -f "$SERVER_JAR"
        return 1
    fi
}

# --- Download logic ---
if [ -f "$SERVER_JAR" ] && is_jar_valid "$SERVER_JAR"; then
    echo "ℹ️  File $SERVER_JAR already exists and is valid."
else
    [ -f "$SERVER_JAR" ] && rm -f "$SERVER_JAR"
    if ! download_paper; then
        echo "⚠️  First attempt failed. Retrying in 5 seconds..."
        sleep 5
        if ! download_paper; then
            echo "❌ Failed to download a valid JAR after two attempts."
            exit 1
        fi
    fi
fi

# --- EULA ---
if [ ! -f "eula.txt" ]; then
    echo "📄 Creating eula.txt..."
    echo "eula=true" > eula.txt
else
    echo "ℹ️  eula.txt already exists."
fi

# --- Memory settings ---
MAX_PERCENT=${MAX_RAM_PERCENT:-80.0}
INIT_PERCENT=${INIT_RAM_PERCENT:-40.0}
echo "🧠 JVM: MaxRAMPercentage=$MAX_PERCENT%, InitialRAMPercentage=$INIT_PERCENT%"

# --- Launch ---
echo "🚀 Starting Paper 1.21.11 (build 116) server..."
exec "$JAVA_CMD" -XX:MaxRAMPercentage="$MAX_PERCENT" -XX:InitialRAMPercentage="$INIT_PERCENT" -jar "$SERVER_JAR" nogui
