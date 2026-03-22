"use client";

import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { searchAll } from "@/lib/supabase/queries";

export function useSearch(query: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["search", query],
    queryFn: async () => {
      const result = await searchAll(supabase, query);
      if (result.partsError) throw result.partsError;
      return result;
    },
    enabled: query.length >= 2,
  });
}
