const fs = require('fs');
const path = require('path');

function autoConfig() {
  const envPath = path.join(__dirname, '.env');
  if (!fs.existsSync(envPath)) {
    fs.copyFileSync(path.join(__dirname, '.env.example'), envPath);
    console.log('[✓] Created .env from example');
  }

  const dirs = ['cache', 'artifacts'];
  dirs.forEach(d => {
    const p = path.join(__dirname, d);
    if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
  });

  console.log('[✓] Auto-config complete. Run: npm install && npx hardhat compile');
}

autoConfig();
