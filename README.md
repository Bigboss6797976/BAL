# 💀 Blockchain Attack Lab v2.0

Advanced Smart Contract Attack Vectors & Security Testing Framework

## ⚠️ 免责声明

**本项目仅用于安全研究、教育和漏洞演示目的。** 所有代码应在本地测试网或私有环境中运行，**切勿在主网或他人合约上使用**。

## 📦 项目结构

```
blockchain-attack-lab/
├── contracts/           # 攻击合约
│   ├── backdoors/       # 后门代币 + 重入
│   ├── gas/            # Gas攻击
│   ├── mev/            # MEV/三明治攻击
│   ├── phishing/       # 钓鱼攻击
│   ├── FullChainAttack.sol    # 全链协调器
│   ├── FlashLoanAttack.sol    # 闪电贷
│   ├── AccessControlAttack.sol # 访问控制
│   ├── RandomnessAttack.sol     # 随机数
│   ├── DelegateAttack.sol       # 委托调用
│   ├── SelfDestructAttack.sol   # 自毁
│   ├── StorageCollisionAttack.sol # 存储碰撞
│   ├── TimestampAttack.sol      # 时间戳
│   └── BatchAttack.sol          # 批量攻击
├── scripts/
│   ├── deploy.js              # 部署脚本
│   ├── attacks/               # 16个攻击执行脚本
│   └── run-all-attacks.js     # 全链测试
├── frontend/                  # Web界面
├── test/                      # 完整测试套件
├── server.js                  # API服务器
└── docs/                      # 文档
```

## 🚀 快速开始

### 标准环境

```bash
npm install
node auto-config.js
npx hardhat compile
npx hardhat run scripts/deploy.js --network hardhat
npm run attack:reentrancy
```

### Termux/Android

```bash
# 1. 修复Termux环境
bash termux-fix.sh

# 2. 使用本地Hardhat
./hardhat-local.sh compile
./hardhat-local.sh run scripts/deploy.js --network termux

# 3. 启动前端服务器
npm run server
```

## 🎯 攻击向量清单

| # | 攻击类型 | 合约 | 脚本 |
|---|---------|------|------|
| 1 | 重入攻击 | ReentrancyVulnerable + ReentrancyAttacker | `npm run attack:reentrancy` |
| 2 | 闪电贷价格操纵 | FlashLoanAttack | `npm run attack:flashloan` |
| 3 | MEV三明治 | MEVAttack | `npm run attack:mev` |
| 4 | Gas耗尽 | GasAttack | `npm run attack:gas` |
| 5 | 授权陷阱 | ApproveTrap | `npm run attack:phishing` |
| 6 | 后门代币 | Blacklist/Force/Mint Backdoor | `npm run attack:backdoor` |
| 7 | 盲签攻击 | BlindSignAttack | `npm run attack:blind` |
| 8 | QR钓鱼 | QRCodeAttack | `npm run attack:qr` |
| 9 | 访问控制绕过 | AccessControlAttack | `npm run attack:access` |
| 10 | 伪随机数操纵 | RandomnessAttack | `npm run attack:random` |
| 11 | 委托调用注入 | DelegateAttack | `npm run attack:delegate` |
| 12 | 自毁/强制转账 | SelfDestructAttack | `npm run attack:selfdestruct` |
| 13 | 存储碰撞 | StorageCollisionAttack | `npm run attack:storage` |
| 14 | 时间戳操纵 | TimestampAttack | `npm run attack:time` |
| 15 | 批量攻击 | BatchAttack | `npm run attack:batch` |
| 16 | 全链组合 | FullChainAttack | `npm run attack:fullchain` |

## 🧪 测试

```bash
npx hardhat test
```

16个测试套件，覆盖所有攻击向量。

## 🌐 前端界面

```bash
npm run server
# 访问 http://localhost:3000
```

提供可视化界面执行所有攻击，实时查看日志和结果。

## 📱 Termux/Android 特别说明

由于Android/Termux环境的限制：
- 使用 `termux-fix.sh` 修复npm symlink问题
- 使用 `./hardhat-local.sh` 替代 `npx hardhat`
- 设置 `NODE_OPTIONS=--max-old-space-size=1536` 防止内存不足

## 🔧 环境变量

```env
PRIVATE_KEY=0x...
RPC_URL=http://127.0.0.1:8545
CHAIN_ID=31337
```

## 📄 许可证

MIT - 教育用途
