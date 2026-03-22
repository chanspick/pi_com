"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import {
  fetchOrders,
  fetchOrderById,
  cancelOrder,
} from "@/lib/supabase/queries";

// 주문 목록 조회 (구매자 기준)
export function useOrders(userId: string | undefined, status?: string) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["orders", userId, status],
    queryFn: async () => {
      if (!userId) throw new Error("userId가 필요합니다.");
      const result = await fetchOrders(supabase, userId, status);
      if (result.error) throw result.error;
      return result.orders;
    },
    enabled: !!userId,
  });

  return { orders: data ?? [], isLoading, error };
}

// 주문 상세 조회
export function useOrderDetail(orderId: string | undefined) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["order", orderId],
    queryFn: async () => {
      if (!orderId) throw new Error("orderId가 필요합니다.");
      const result = await fetchOrderById(supabase, orderId);
      if (result.error) throw result.error;
      return result.order;
    },
    enabled: !!orderId,
  });

  return { order: data ?? null, isLoading, error };
}

// 주문 취소
export function useCancelOrder() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      orderId,
    }: {
      orderId: string;
      userId: string;
    }) => {
      const result = await cancelOrder(supabase, orderId);
      if (result.error) throw result.error;
      return result;
    },
    onSuccess: (_data, { userId, orderId }) => {
      // 주문 목록 및 상세 캐시 무효화
      queryClient.invalidateQueries({ queryKey: ["orders", userId] });
      queryClient.invalidateQueries({ queryKey: ["order", orderId] });
    },
  });
}
