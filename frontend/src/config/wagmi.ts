import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { defineChain } from "viem";

// ── LitVM Testnet chain definition ──
export const litvmTestnet = defineChain({
  id: 1337, // ← replace with actual LitVM Testnet chainId
  name: "LitVM Testnet",
  nativeCurrency: {
    decimals: 18,
    name: "LitVM ETH",
    symbol: "ETH",
  },
  rpcUrls: {
    default: {
      http: [process.env.NEXT_PUBLIC_RPC_URL || "https://rpc.litvm-testnet.io"],
    },
  },
  blockExplorers: {
    default: {
      name: "LitVM Explorer",
      url: process.env.NEXT_PUBLIC_EXPLORER_URL || "https://explorer.litvm-testnet.io",
    },
  },
  testnet: true,
});

export const wagmiConfig = getDefaultConfig({
  appName: "LitCount",
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || "YOUR_PROJECT_ID",
  chains: [litvmTestnet],
  ssr: true,
});

// ── Contract addresses ──
export const CONTRACT_ADDRESSES = {
  zkLTC: process.env.NEXT_PUBLIC_ZKLTC_ADDRESS as `0x${string}`,
  pool:  process.env.NEXT_PUBLIC_POOL_ADDRESS  as `0x${string}`,
};
