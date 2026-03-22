"use client";

import { useInfiniteQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import {
  fetchListings,
  ListingsQueryParams,
  ListingWithBasePart,
} from "@/lib/supabase/queries";

export function useListings(params: Omit<ListingsQueryParams, "cursor"> = {}) {
  const supabase = createClient();

  return useInfiniteQuery({
    queryKey: ["listings", params],
    queryFn: async ({ pageParam }) => {
      const result = await fetchListings(supabase, {
        ...params,
        cursor: pageParam as string | undefined,
      });

      if (result.error) {
        throw result.error;
      }

      return result;
    },
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (lastPage) => {
      if (lastPage.listings.length < (params.limit ?? 20)) {
        return undefined;
      }
      const lastItem = lastPage.listings[lastPage.listings.length - 1];
      return lastItem?.created_at;
    },
  });
}

export type { ListingWithBasePart };
