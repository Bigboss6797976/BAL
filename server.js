const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'frontend')));

// API: 获取部署地址
app.get('/api/deployments', (req, res) => {
    const deployPath = path.join(__dirname, 'deployments.json');
    if (fs.existsSync(deployPath)) {
        res.json(JSON.parse(fs.readFileSync(deployPath)));
    } else {
        res.status(404).json({error: 'Deployments not found'});
    }
});

// API: 执行部署
app.post('/api/deploy', (req, res) => {
    exec('node scripts/deploy.js --network hardhat', {cwd: __dirname}, (err, stdout, stderr) => {
        if (err) return res.status(500).json({error: err.message, stderr});
        res.json({success: true, output: stdout});
    });
});

// API: 执行全链攻击
app.post('/api/attack-all', (req, res) => {
    exec('node scripts/run-all-attacks.js', {cwd: __dirname}, (err, stdout, stderr) => {
        if (err) return res.status(500).json({error: err.message, stderr});
        res.json({success: true, output: stdout});
    });
});

// API: 执行特定攻击
app.post('/api/attack/:type', (req, res) => {
    const scriptMap = {
        reentrancy: 'scripts/attacks/reentrancy-attack.js',
        flashloan: 'scripts/attacks/flashloan-attack.js',
        gas: 'scripts/attacks/gas-attack.js',
        mev: 'scripts/attacks/mev-attack.js',
        phishing: 'scripts/attacks/phishing-attack.js',
        backdoor: 'scripts/attacks/backdoor-attack.js',
        blind: 'scripts/attacks/blind-sign-attack.js',
        qr: 'scripts/attacks/qr-attack.js',
        access: 'scripts/attacks/access-control-attack.js',
        random: 'scripts/attacks/randomness-attack.js',
        delegate: 'scripts/attacks/delegate-attack.js',
        selfdestruct: 'scripts/attacks/selfdestruct-attack.js',
        storage: 'scripts/attacks/storage-collision-attack.js',
        timestamp: 'scripts/attacks/timestamp-attack.js',
        batch: 'scripts/attacks/batch-attack.js',
        fullchain: 'scripts/attacks/full-chain-attack.js'
    };

    const script = scriptMap[req.params.type];
    if (!script) return res.status(400).json({error: 'Unknown attack type'});

    exec(`node ${script}`, {cwd: __dirname}, (err, stdout, stderr) => {
        if (err) return res.status(500).json({error: err.message, stderr});
        res.json({success: true, output: stdout});
    });
});

// API: 环境检查
app.get('/api/health', (req, res) => {
    res.json({status: 'ok', version: '2.0.0'});
});

app.listen(PORT, () => {
    console.log(`💀 BAL Server running on http://localhost:${PORT}`);
});
