"use client";

import { useMemo, useState } from "react";
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ReferenceLine,
} from "recharts";
import { cn } from "@/lib/utils";
import type { PriceHistoryRow } from "@/lib/supabase/queries";

function formatCompactPrice(price: number): string {
  if (price >= 10000) return (price / 10000).toFixed(1).replace(".0", "") + "만";
  if (price >= 1000) return (price / 1000).toFixed(0) + "천";
  return String(price);
}

function formatDate(dateStr: string): string {
  const d = new Date(dateStr);
  return (d.getMonth() + 1) + "/" + d.getDate();
}

interface PriceHistoryChartProps {
  history: PriceHistoryRow[];
  currentPrice?: number;
}

const periods = [
  { label: "7일", days: 7 },
  { label: "30일", days: 30 },
  { label: "90일", days: 90 },
];

export function PriceHistoryChart({ history, currentPrice }: PriceHistoryChartProps) {
  const [selectedDays, setSelectedDays] = useState(30);

  const chartData = useMemo(() => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - selectedDays);

    return history
      .filter((h) => new Date(h.recorded_at) >= cutoff)
      .map((h) => ({
        date: formatDate(h.recorded_at),
        price: h.price,
        fullDate: new Date(h.recorded_at).toLocaleDateString("ko-KR"),
      }));
  }, [history, selectedDays]);

  if (chartData.length === 0) {
    return (
      <div className="flex items-center justify-center h-[240px] text-[13px] text-muted-foreground rounded-xl border bg-card">
        시세 데이터가 없습니다
      </div>
    );
  }

  const prices = chartData.map((d) => d.price);
  const minPrice = Math.min(...prices);
  const maxPrice = Math.max(...prices);
  const padding = Math.max((maxPrice - minPrice) * 0.1, 1000);

  return (
    <div className="space-y-3">
      {/* Period selector */}
      <div className="flex gap-1.5">
        {periods.map((p) => (
          <button
            key={p.days}
            onClick={() => setSelectedDays(p.days)}
            className={cn(
              "px-3 py-1 rounded-md text-[12px] font-medium transition-colors",
              selectedDays === p.days
                ? "bg-primary text-primary-foreground"
                : "bg-muted text-muted-foreground hover:text-foreground"
            )}
          >
            {p.label}
          </button>
        ))}
      </div>

      {/* Chart */}
      <div className="h-[240px] w-full">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={chartData} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis
              dataKey="date"
              tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
              tickLine={false}
              axisLine={{ stroke: "hsl(var(--border))" }}
            />
            <YAxis
              tickFormatter={(v) => formatCompactPrice(v) + "원"}
              tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
              tickLine={false}
              axisLine={false}
              domain={[minPrice - padding, maxPrice + padding]}
              width={65}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: "hsl(var(--card))",
                border: "1px solid hsl(var(--border))",
                borderRadius: 8,
                fontSize: 13,
                padding: "8px 12px",
              }}
              formatter={(value) => [new Intl.NumberFormat("ko-KR").format(Number(value)) + "원", "가격"]}
              labelFormatter={(_, payload) => payload?.[0]?.payload?.fullDate ?? ""}
            />
            {currentPrice && (
              <ReferenceLine
                y={currentPrice}
                stroke="hsl(var(--success))"
                strokeDasharray="4 4"
                strokeWidth={1.5}
              />
            )}
            <Line
              type="monotone"
              dataKey="price"
              stroke="#3B82F6"
              strokeWidth={2}
              dot={false}
              activeDot={{ r: 4, fill: "#3B82F6", stroke: "#fff", strokeWidth: 2 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Legend */}
      <div className="flex items-center gap-4 text-[11px] text-muted-foreground">
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-0.5 bg-[#3B82F6] rounded-full" />
          <span>거래 가격</span>
        </div>
        {currentPrice && (
          <div className="flex items-center gap-1.5">
            <div className="w-3 h-0.5 bg-[hsl(var(--success))] rounded-full" style={{ borderTop: "1px dashed" }} />
            <span>현재 최저가</span>
          </div>
        )}
      </div>
    </div>
  );
}
