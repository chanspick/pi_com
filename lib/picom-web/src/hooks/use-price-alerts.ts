"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import {
  fetchPriceAlerts,
  createPriceAlert,
  togglePriceAlert,
  deletePriceAlert,
} from "@/lib/supabase/queries";

// 가격 알림 목록 조회
export function usePriceAlerts(userId: string | undefined) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["priceAlerts", userId],
    queryFn: async () => {
      if (!userId) throw new Error("userId가 필요합니다.");
      const result = await fetchPriceAlerts(supabase, userId);
      if (result.error) throw result.error;
      return result.alerts;
    },
    enabled: !!userId,
  });

  return { alerts: data ?? [], isLoading, error };
}

// 가격 알림 생성
export function useCreatePriceAlert() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (alert: {
      user_id: string;
      base_part_id: string;
      target_price: number;
      part_name?: string;
      price_at_creation?: number;
    }) => {
      const result = await createPriceAlert(supabase, alert);
      if (result.error) throw result.error;
      return result.alert;
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ["priceAlerts", variables.user_id] });
    },
  });
}

// 가격 알림 활성/비활성 토글
export function useTogglePriceAlert() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      alertId,
      isActive,
    }: {
      alertId: string;
      isActive: boolean;
      userId: string;
    }) => {
      const result = await togglePriceAlert(supabase, alertId, isActive);
      if (result.error) throw result.error;
      return result;
    },
    onSuccess: (_data, { userId }) => {
      queryClient.invalidateQueries({ queryKey: ["priceAlerts", userId] });
    },
  });
}

// 가격 알림 삭제
export function useDeletePriceAlert() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      alertId,
    }: {
      alertId: string;
      userId: string;
    }) => {
      const result = await deletePriceAlert(supabase, alertId);
      if (result.error) throw result.error;
      return result;
    },
    onSuccess: (_data, { userId }) => {
      queryClient.invalidateQueries({ queryKey: ["priceAlerts", userId] });
    },
  });
}
