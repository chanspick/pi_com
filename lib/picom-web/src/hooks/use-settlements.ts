"use client";

import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { fetchSettlements } from "@/lib/supabase/queries";

// 판매자의 정산 목록 조회
export function useSettlements(sellerId: string | undefined, status?: string) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["settlements", sellerId, status],
    queryFn: async () => {
      if (!sellerId) throw new Error("sellerId가 필요합니다.");
      const result = await fetchSettlements(supabase, sellerId, status);
      if (result.error) throw result.error;
      return result.settlements;
    },
    enabled: !!sellerId,
  });

  return { settlements: data ?? [], isLoading, error };
}
