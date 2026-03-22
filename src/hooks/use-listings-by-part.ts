"use client";

import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { fetchListingsByBasePart } from "@/lib/supabase/queries";

export function useListingsByBasePart(basePartId: string, sort: string = "newest") {
  const supabase = createClient();

  return useQuery({
    queryKey: ["listings-by-part", basePartId, sort],
    queryFn: async () => {
      const result = await fetchListingsByBasePart(supabase, basePartId, { sort, limit: 50 });
      if (result.error) throw result.error;
      return result;
    },
    enabled: !!basePartId,
  });
}
