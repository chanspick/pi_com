"use client";

import { createClient } from "@/lib/supabase/client";
import { fetchAdminStats } from "@/lib/supabase/queries";
import { formatPrice } from "@/lib/utils";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  DollarSign,
  ShoppingCart,
  FileText,
  Package,
} from "lucide-react";
import { useEffect, useState } from "react";

interface AdminStats {
  todayRevenue: number;
  todayOrderCount: number;
  pendingSellRequests: number;
  activeListings: number;
}

export default function AdminDashboardPage() {
  const supabase = createClient();
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const data = await fetchAdminStats(supabase);
      setStats(data);
      setLoading(false);
    }
    load();
  }, [supabase]);

  if (loading) {
    return (
      <div>
        <h1 className="text-xl font-bold mb-4">대시보드</h1>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Card key={i}>
              <CardHeader>
                <Skeleton className="h-4 w-20" />
              </CardHeader>
              <CardContent>
                <Skeleton className="h-8 w-28" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  const statCards = [
    {
      label: "오늘 매출",
      value: formatPrice(stats?.todayRevenue ?? 0),
      icon: DollarSign,
      color: "text-green-600",
      bgColor: "bg-green-100 dark:bg-green-900/30",
    },
    {
      label: "신규 주문",
      value: `${stats?.todayOrderCount ?? 0}건`,
      icon: ShoppingCart,
      color: "text-blue-600",
      bgColor: "bg-blue-100 dark:bg-blue-900/30",
    },
    {
      label: "판매 신청 대기",
      value: `${stats?.pendingSellRequests ?? 0}건`,
      icon: FileText,
      color: "text-orange-600",
      bgColor: "bg-orange-100 dark:bg-orange-900/30",
    },
    {
      label: "활성 매물",
      value: `${stats?.activeListings ?? 0}건`,
      icon: Package,
      color: "text-purple-600",
      bgColor: "bg-purple-100 dark:bg-purple-900/30",
    },
  ];

  return (
    <div>
      <h1 className="text-xl font-bold mb-4">대시보드</h1>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {statCards.map((card) => (
          <Card key={card.label}>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  {card.label}
                </CardTitle>
                <div className={`rounded-lg p-2 ${card.bgColor}`}>
                  <card.icon className={`size-4 ${card.color}`} />
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold">{card.value}</p>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
