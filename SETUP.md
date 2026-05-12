# SETUP.md - 部署指南

## 系统要求

- Node.js >= 18
- npm >= 9
- Git (可选)

## 安装步骤

### 1. 克隆/解压项目

```bash
cd /storage/emulated/0/BAL  # Android
# 或
cd ~/blockchain-attack-lab    # Linux/Mac
```

### 2. 安装依赖

```bash
npm install
```

如果遇到权限错误（Termux）：
```bash
bash termux-fix.sh
```

### 3. 配置环境

```bash
node auto-config.js
```

这会创建 `.env` 文件并设置目录。

### 4. 编译合约

```bash
npx hardhat compile
```

Termux:
```bash
./hardhat-local.sh compile
```

### 5. 部署

本地网络:
```bash
npx hardhat node &
npx hardhat run scripts/deploy.js --network localhost
```

Hardhat网络:
```bash
npx hardhat run scripts/deploy.js --network hardhat
```

### 6. 运行攻击

```bash
npm run attack:reentrancy
npm run attack:gas
npm run attack:backdoor
# ... etc
```

### 7. 启动前端

```bash
npm run server
```

访问 `http://localhost:3000`

## 故障排除

### Hardhat not found
```bash
npm install -g hardhat  # 不推荐
# 或
bash termux-fix.sh
```

### 内存不足
```bash
export NODE_OPTIONS="--max-old-space-size=2048"
```

### 编译错误
确保 Solidity 版本匹配 (0.8.20)
```bash
npx hardhat clean
npx hardhat compile
```
