"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import {
  fetchRefundsByUser,
  fetchRefundByOrderId,
  createRefund,
} from "@/lib/supabase/queries";

// 사용자의 환불 목록 조회
export function useRefunds(userId: string | undefined) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["refunds", userId],
    queryFn: async () => {
      if (!userId) throw new Error("userId가 필요합니다.");
      const result = await fetchRefundsByUser(supabase, userId);
      if (result.error) throw result.error;
      return result.refunds;
    },
    enabled: !!userId,
  });

  return { refunds: data ?? [], isLoading, error };
}

// 특정 주문의 환불 조회
export function useRefundByOrder(orderId: string | undefined) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["refund", "order", orderId],
    queryFn: async () => {
      if (!orderId) throw new Error("orderId가 필요합니다.");
      const result = await fetchRefundByOrderId(supabase, orderId);
      if (result.error) throw result.error;
      return result.refund;
    },
    enabled: !!orderId,
  });

  return { refund: data ?? null, isLoading, error };
}

// 환불 요청 생성
export function useCreateRefund() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (params: {
      order_id: string;
      user_id: string;
      amount: number;
      reason?: string;
    }) => {
      const result = await createRefund(supabase, params);
      if (result.error) throw result.error;
      return result.refund;
    },
    onSuccess: (_data, variables) => {
      // 환불 목록 및 주문 캐시 무효화
      queryClient.invalidateQueries({ queryKey: ["refunds", variables.user_id] });
      queryClient.invalidateQueries({ queryKey: ["refund", "order", variables.order_id] });
      queryClient.invalidateQueries({ queryKey: ["order", variables.order_id] });
      queryClient.invalidateQueries({ queryKey: ["orders", variables.user_id] });
    },
  });
}
