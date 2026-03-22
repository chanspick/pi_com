"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import {
  fetchMyListings,
  deleteListing,
  updateListingStatus,
} from "@/lib/supabase/queries";

// 내 매물 목록 조회 (판매자 기준)
export function useMyListings(userId: string | undefined, status?: string) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["my-listings", userId, status],
    queryFn: async () => {
      if (!userId) throw new Error("userId가 필요합니다.");
      const result = await fetchMyListings(supabase, userId, status);
      if (result.error) throw result.error;
      return result.listings;
    },
    enabled: !!userId,
  });

  return { listings: data ?? [], isLoading, error };
}

// 매물 삭제 (소프트 삭제: status -> "deleted")
export function useDeleteListing() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      listingId,
    }: {
      listingId: string;
      userId: string;
    }) => {
      const result = await deleteListing(supabase, listingId);
      if (result.error) throw result.error;
      return result;
    },
    onSuccess: (_data, { userId }) => {
      // 내 매물 목록 캐시 무효화
      queryClient.invalidateQueries({ queryKey: ["my-listings", userId] });
    },
  });
}

// 매물 상태 변경
export function useUpdateListingStatus() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      listingId,
      status,
    }: {
      listingId: string;
      status: string;
      userId: string;
    }) => {
      const result = await updateListingStatus(supabase, listingId, status);
      if (result.error) throw result.error;
      return result;
    },
    onSuccess: (_data, { userId }) => {
      queryClient.invalidateQueries({ queryKey: ["my-listings", userId] });
    },
  });
}
