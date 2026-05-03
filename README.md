# LitCount 🟢

> **Just stake it dan get reward.**

Pool staking DeFi protocol on LitVM Testnet. Stake `0.1 $zkLTC`, win the jackpot or earn base rewards every 21 hours.

**Mechanism: Save & Win**
- 🥇 **70%** → Lucky jackpot winner (random draw)
- 👥 **20%** → Shared equally to ALL stakers
- 🏦 **10%** → Protocol treasury

---

## Tech Stack

| Layer | Tech |
|---|---|
| Smart Contract | Solidity 0.8.20 + Foundry |
| Frontend | Next.js 14 + React 18 |
| Wallet | wagmi v2 + RainbowKit v2 |
| Styling | Tailwind CSS |
| Deploy Contract | LitVM Testnet (Foundry) |
| Deploy App | Vercel |

---

## Project Structure

```
litcount/
├── contracts/
│   ├── src/
│   │   ├── zkLTC.sol          # ERC20 testnet token + faucet
│   │   └── LitCountPool.sol   # Main pool contract
│   ├── test/
│   │   └── LitCountPool.t.sol # Foundry tests
│   ├── script/
│   │   └── Deploy.s.sol       # Deployment script
│   └── foundry.toml
├── frontend/
│   ├── src/
│   │   ├── app/               # Next.js app router
│   │   ├── components/        # UI components
│   │   ├── hooks/             # Custom React hooks
│   │   └── lib/               # Config, ABIs
│   └── package.json
└── .github/workflows/ci.yml
```

---

## Setup & Deploy

### 1. Clone & Install Foundry

```bash
git clone https://github.com/yourusername/litcount
cd litcount

# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Deploy Smart Contracts

```bash
cd contracts

# Install OZ dependencies
forge install OpenZeppelin/openzeppelin-contracts

# Copy env
cp ../.env.example .env
# Fill in PRIVATE_KEY and LITVM_RPC_URL

# Run tests
forge test -vvv

# Deploy to LitVM Testnet
forge script script/Deploy.s.sol:DeployLitCount \
  --rpc-url $LITVM_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

### 3. Update Contract Addresses

After deployment, update `frontend/src/lib/config.ts`:

```ts
export const CONTRACTS = {
  zkLTC:        "0xYOUR_ZKLTC_ADDRESS",
  LitCountPool: "0xYOUR_POOL_ADDRESS",
};

// Also update chain ID for LitVM Testnet
export const LITVM_TESTNET = {
  id: YOUR_CHAIN_ID,
  ...
};
```

### 4. Run Frontend

```bash
cd frontend
npm install
cp .env.example .env.local
# Fill in env vars

npm run dev
# → http://localhost:3000
```

### 5. Deploy to Vercel

```bash
# Push to GitHub
git push origin main

# Connect repo to Vercel
# Add environment variables in Vercel dashboard
# Vercel auto-deploys on push to main
```

---

## Smart Contract Architecture

### `zkLTC.sol`
- ERC20 testnet token
- `faucet()` → claim 10 zkLTC every 24 hours
- `adminMint()` → owner can mint for pool seeding

### `LitCountPool.sol`
- `joinPool()` → stake 0.1 zkLTC, enter pool
- `triggerDrawPhase()` → call after 21 hours (permissionless)
- `executeDraw()` → pick winner during 21-min window
- `forceReset()` → safety valve if draw window expires
- `getPoolStatus()` → full pool state for frontend

**Reward split:**
```
Total pool = N × 0.1 zkLTC
Jackpot    = Total × 70%  → random winner
Stakers    = Total × 20%  → split equally
Protocol   = Total × 10%  → treasury
```

**Draw rules:**
- ✅ ≥ 21 users → draw happens, pool resets
- ❌ < 21 users → no draw, pool continues, participants kept, timer resets

---

## Pool Mechanism Flow

```
User joins (0.1 zkLTC stake)
        ↓
Pool open 21 hours
        ↓
triggerDrawPhase() called
        ↓
 ≥21 users?
   YES → 21 min draw window → executeDraw() → 70% winner + 20% all + 10% protocol → pool resets
   NO  → notification + pool continues → timer restarts (participants kept)
```

---

## Security Notes

> ⚠️ **Testnet Only** - This uses pseudo-random number generation. For mainnet, replace with [Chainlink VRF](https://docs.chain.link/vrf).

- `ReentrancyGuard` on all state-changing functions
- `Pausable` for emergency stop
- `SafeERC20` for all token transfers
- `Ownable` for admin functions
- Emergency withdrawal only when paused

---

## Roadmap

- [ ] Mainnet deployment with Chainlink VRF
- [ ] Multiple pool tiers (different stake amounts)
- [ ] Mobile app (React Native)
- [ ] Referral system
- [ ] Governance token

---

**About:** Becoming a Truly Rich Person | **Category:** DeFi | **Network:** LitVM Testnet
