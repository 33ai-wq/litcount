// Contract addresses on LitVM Testnet
export const CONTRACTS = {
  zkLTC: "0xb2265fd707bbdfccf7a789072eaeab9be35ab9f3",
  LitCountPool: "0x557cf23b764c7665529ccf62c7bf19824e935d3e",
} as const;

// LitVM LiteForge chain config
export const LITVM_TESTNET = {
  id: 4441,
  name: "LitVM LiteForge",
  nativeCurrency: { name: "zkLTC", symbol: "zkLTC", decimals: 18 },
  rpcUrls: {
    default: { http: ["https://liteforge.rpc.caldera.xyz/http"] },
  },
  blockExplorers: {
    default: { name: "LiteForge Explorer", url: "https://liteforge.explorer.caldera.xyz" },
  },
  testnet: true,
} as const;

// Pool constants (match contract)
export const POOL_CONFIG = {
  STAKE_AMOUNT:   BigInt("100000000000000000"), // 0.1 ether
  POOL_DURATION:  21 * 60 * 60,                 // 21 hours in seconds
  DRAW_WINDOW:    21 * 60,                       // 21 minutes in seconds
  MIN_USERS:      21,
  JACKPOT_PCT:    70,
  STAKER_PCT:     20,
  PROTOCOL_PCT:   10,
};
