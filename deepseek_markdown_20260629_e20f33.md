# Paper 1.21.11 Server Startup Script

This script automatically downloads and runs a **Paper 1.21.11 (build 116)** Minecraft server.  
It handles Java installation (if missing or outdated), downloads the server JAR, accepts the EULA, and launches the server with optimized memory settings.

## Features

- **Automatic Java 21+ detection** – uses system Java if available, otherwise downloads Temurin JDK 21 locally.
- **Validates JAR integrity** – checks the ZIP header to ensure a correct download.
- **Retry mechanism** – retries the download once if it fails.
- **EULA auto‑acceptance** – creates `eula.txt` with `eula=true`.
- **Memory tuning** – uses `-XX:MaxRAMPercentage` and `-XX:InitialRAMPercentage` (adjustable via environment variables).
- **No‑GUI mode** – runs the server in console mode (`nogui`).

## Requirements

- **Linux** (or any system with Bash and common tools: `curl`, `tar`, `dd`, `od`).
- **Internet connection** for downloading Java and the Paper JAR.

## Usage

1. **Clone or download** this script into an empty directory.
2. **Make it executable**:
   ```bash
   chmod +x paper-start.sh