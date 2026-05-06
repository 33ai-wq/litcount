import { createWalletClient, http, publicActions } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { LITVM_TESTNET } from "@/lib/config";
import { LITCOUNT_POOL_ABI } from "@/lib/abi";

const POOL_ADDRESS = "0x7903e5B54913Fd67dA541F478b17c8B342C82b83" as const;
const RPC_URL      = "https://liteforge.rpc.caldera.xyz/http";

export async function GET(request: Request) {
  const auth = request.headers.get("authorization");
  if (auth !== `Bearer ${process.env.CRON_SECRET}`) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const account = privateKeyToAccount(
      process.env.DEPLOYER_PRIVATE_KEY as `0x${string}`
    );

    const client = createWalletClient({
      account,
      chain: LITVM_TESTNET as any,
      transport: http(RPC_URL),
    }).extend(publicActions);

    const status = await client.readContract({
      address: POOL_ADDRESS,
      abi: LITCOUNT_POOL_ABI,
      functionName: "getPoolStatus",
    }) as any;

    const timeLeft = Number(status[3]);
    const inDraw   = Boolean(status[4]);
    const count    = Number(status[1]);

    if (timeLeft === 0 && !inDraw) {
      const hash = await client.writeContract({
        address: POOL_ADDRESS,
        abi: LITCOUNT_POOL_ABI,
        functionName: "triggerDrawPhase",
      });
      return Response.json({ action: "triggerDrawPhase", participants: count, hash });
    }

    if (inDraw) {
      const drawLeft = await client.readContract({
        address: POOL_ADDRESS,
        abi: LITCOUNT_POOL_ABI,
        functionName: "getDrawPhaseTimeLeft",
      }) as bigint;

      if (Number(drawLeft) > 0) {
        const hash = await client.writeContract({
          address: POOL_ADDRESS,
          abi: LITCOUNT_POOL_ABI,
          functionName: "executeDraw",
        });
        return Response.json({ action: "executeDraw", participants: count, hash });
      } else {
        const hash = await client.writeContract({
          address: POOL_ADDRESS,
          abi: LITCOUNT_POOL_ABI,
          functionName: "forceReset",
        });
        return Response.json({ action: "forceReset", participants: count, hash });
      }
    }

    return Response.json({
      action: "none",
      message: "Pool still running",
      timeLeft,
      participants: count,
    });

  } catch (error: any) {
    return Response.json({ error: error.message }, { status: 500 });
  }
}
