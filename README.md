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
