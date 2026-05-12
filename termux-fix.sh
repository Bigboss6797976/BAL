#!/bin/bash
# BAL - Termux Fix v3 (NPM #4828 workaround)

echo "========================================"
echo "  BAL - Termux Fix v3"
echo "========================================"

cd "$(dirname "$0")"

# 1. Nuke everything
rm -rf node_modules package-lock.json yarn.lock
npm cache clean --force
rm -rf ~/.npm/_cacache

# 2. Fix permissions
chmod +x *.sh 2>/dev/null || true

# 3. Install with legacy peer deps (绕过版本冲突)
echo "[+] Installing dependencies..."
npm install --legacy-peer-deps --no-bin-links --prefer-offline 2>&1 | tee npm.log

# 4. If fail, force install
if [ $? -ne 0 ]; then
    echo "[!] Normal install failed, trying --force..."
    npm install --force --no-bin-links --prefer-offline 2>&1 | tee npm-force.log
fi

# 5. Verify hardhat version
HH_VER=$(cat node_modules/hardhat/package.json 2>/dev/null | grep '"version"' | head -1)
echo "[i] Hardhat version: $HH_VER"

# 6. Create wrapper
cat > hardhat-local.sh << 'EOF'
#!/bin/bash
export NODE_OPTIONS="--max-old-space-size=1536"
node ./node_modules/hardhat/internal/cli/bootstrap.js "$@"
EOF
chmod +x hardhat-local.sh

cat > node-hh.sh << 'EOF'
#!/bin/bash
export NODE_OPTIONS="--max-old-space-size=1536"
node "$@"
EOF
chmod +x node-hh.sh

echo ""
echo "[✓] Fix complete!"
echo "[i] Run: ./hardhat-local.sh compile"
echo "========================================"
