"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import {
  fetchSellRequests,
  createSellRequest,
  updateSellRequest,
} from "@/lib/supabase/queries";
import type { Json } from "@/types/database.types";

// 판매 신청 목록 조회
export function useSellRequests(
  userId: string | undefined,
  status?: string
) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["sell-requests", userId, status],
    queryFn: async () => {
      if (!userId) throw new Error("userId가 필요합니다.");
      const result = await fetchSellRequests(supabase, userId, status);
      if (result.error) throw result.error;
      return result.sellRequests;
    },
    enabled: !!userId,
  });

  return { sellRequests: data ?? [], isLoading, error };
}

// 판매 신청 생성
export function useCreateSellRequest() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (request: {
      user_id: string;
      category: string;
      title: string;
      description?: string;
      desired_price?: number;
      images?: string[];
      specs?: Json;
      is_secondhand?: boolean;
      has_warranty?: boolean;
      warranty_months_left?: number;
    }) => {
      const result = await createSellRequest(supabase, request);
      if (result.error) throw result.error;
      return result.sellRequest;
    },
    onSuccess: (_data, variables) => {
      // 판매 신청 목록 캐시 무효화
      queryClient.invalidateQueries({
        queryKey: ["sell-requests", variables.user_id],
      });
    },
  });
}

// 판매 신청 취소 (status를 "cancelled"로 변경)
export function useCancelSellRequest() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      requestId,
      userId,
    }: {
      requestId: string;
      userId: string;
    }) => {
      const result = await updateSellRequest(supabase, requestId, {
        status: "cancelled",
      });
      if (result.error) throw result.error;
      return result.sellRequest;
    },
    onSuccess: (_data, { userId }) => {
      queryClient.invalidateQueries({
        queryKey: ["sell-requests", userId],
      });
    },
  });
}
