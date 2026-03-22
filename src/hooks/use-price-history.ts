"use client";

import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { fetchPriceHistory, PriceHistoryRow } from "@/lib/supabase/queries";

export function usePriceHistory(basePartId: string, days: number = 30) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["price-history", basePartId, days],
    queryFn: async () => {
      const result = await fetchPriceHistory(supabase, basePartId, days);
      if (result.error) throw result.error;
      return result.history;
    },
    enabled: !!basePartId,
  });
}

export type { PriceHistoryRow };
