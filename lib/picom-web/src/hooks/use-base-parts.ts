"use client";

import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { fetchBasePartsByCategory, BasePartRow } from "@/lib/supabase/queries";

export function useBaseParts(category: string, search?: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["base-parts", category, search],
    queryFn: async () => {
      const result = await fetchBasePartsByCategory(supabase, category, search);
      if (result.error) throw result.error;
      return result;
    },
    enabled: !!category,
  });
}

export type { BasePartRow };
