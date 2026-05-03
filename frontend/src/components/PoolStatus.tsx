"use client";

import { usePoolData } from "@/hooks/usePoolData";
import { useCountdown } from "@/hooks/useCountdown";
import { Users, Clock, Trophy, TrendingUp, AlertCircle } from "lucide-react";
import { POOL_CONFIG } from "@/lib/config";

export function PoolStatus() {
  const {
    poolId, participantCount, totalStaked, timeLeft,
    inDrawPhase, jackpotEst, stakerEst, progress,
    drawTimeLeft,
  } = usePoolData();

  const timer = useCountdown(inDrawPhase ? drawTimeLeft : timeLeft);

  return (
    <div className="card-active p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full pulse-green" style={{ background: "#22c55e" }} />
          <span className="text-sm font-medium" style={{ color: "#22c55e" }}>
            {inDrawPhase ? "🎲 Draw Phase" : "⚡ Pool Active"} — Round #{poolId}
          </span>
        </div>
        <span className="text-xs text-gray-500">LitVM Testnet</span>
      </div>

      {/* Timer */}
      <div className="text-center py-4">
        <p className="text-xs text-gray-500 mb-2 uppercase tracking-widest">
          {inDrawPhase ? "Draw closes in" : "Pool closes in"}
        </p>
        <div className="font-mono-timer text-5xl font-bold text-white tracking-wider">
          {timer.formatted}
        </div>
        {inDrawPhase && (
          <p className="text-xs mt-2" style={{ color: "#22c55e" }}>
            🎰 Winner being selected...
          </p>
        )}
      </div>

      {/* Progress bar */}
      <div>
        <div className="flex justify-between text-xs text-gray-400 mb-2">
          <span>{participantCount} users joined</span>
          <span>Min: {POOL_CONFIG.MIN_USERS} users</span>
        </div>
        <div className="w-full h-2 rounded-full" style={{ background: "rgba(255,255,255,0.08)" }}>
          <div
            className="h-2 rounded-full transition-all duration-500"
            style={{
              width: `${progress}%`,
              background: progress >= 100
                ? "linear-gradient(90deg, #22c55e, #86efac)"
                : "linear-gradient(90deg, #16a34a, #22c55e)",
              boxShadow: progress >= 100 ? "0 0 12px rgba(34,197,94,0.5)" : "none",
            }}
          />
        </div>
        {participantCount < POOL_CONFIG.MIN_USERS && (
          <div className="flex items-center gap-1 mt-2 text-xs text-amber-400">
            <AlertCircle size={12} />
            <span>Need {POOL_CONFIG.MIN_USERS - participantCount} more users for draw</span>
          </div>
        )}
      </div>

      {/* Stats grid */}
      <div className="grid grid-cols-2 gap-3">
        <StatCard icon={<Users size={16} />} label="Participants" value={String(participantCount)} />
        <StatCard icon={<TrendingUp size={16} />} label="Total Staked" value={`${totalStaked.toFixed(1)} zkLTC`} />
        <StatCard icon={<Trophy size={16} />} label="🥇 Jackpot" value={`${jackpotEst} zkLTC`} highlight />
        <StatCard icon={<Clock size={16} />} label="👥 Your Share" value={`${stakerEst} zkLTC`} />
      </div>

      {/* Reward split visualization */}
      <div className="rounded-xl p-4 space-y-2" style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.06)" }}>
        <p className="text-xs text-gray-500 uppercase tracking-widest mb-3">Reward Distribution</p>
        <RewardBar label="🥇 Lucky winner" pct={70} color="#22c55e" />
        <RewardBar label="👥 All stakers" pct={20} color="#3b82f6" />
        <RewardBar label="🏦 Protocol"    pct={10} color="#6b7280" />
      </div>
    </div>
  );
}

function StatCard({ icon, label, value, highlight }: {
  icon: React.ReactNode;
  label: string;
  value: string;
  highlight?: boolean;
}) {
  return (
    <div className="rounded-xl p-3" style={{
      background: highlight ? "rgba(34,197,94,0.05)" : "rgba(255,255,255,0.03)",
      border: `1px solid ${highlight ? "rgba(34,197,94,0.2)" : "rgba(255,255,255,0.06)"}`,
    }}>
      <div className="flex items-center gap-1.5 mb-1" style={{ color: highlight ? "#22c55e" : "#6b7280" }}>
        {icon}
        <span className="text-xs">{label}</span>
      </div>
      <p className="font-bold text-white text-sm">{value}</p>
    </div>
  );
}

function RewardBar({ label, pct, color }: { label: string; pct: number; color: string }) {
  return (
    <div className="flex items-center gap-3">
      <span className="text-xs text-gray-400 w-32">{label}</span>
      <div className="flex-1 h-1.5 rounded-full" style={{ background: "rgba(255,255,255,0.06)" }}>
        <div className="h-1.5 rounded-full" style={{ width: `${pct}%`, background: color }} />
      </div>
      <span className="text-xs font-medium text-white w-8 text-right">{pct}%</span>
    </div>
  );
}
