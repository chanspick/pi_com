"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import {
  fetchNotifications,
  fetchUnreadCount,
  markNotificationRead,
  markAllNotificationsRead,
} from "@/lib/supabase/queries";

// 알림 목록 조회
export function useNotifications(userId: string | undefined) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["notifications", userId],
    queryFn: async () => {
      if (!userId) throw new Error("userId가 필요합니다.");
      const result = await fetchNotifications(supabase, userId);
      if (result.error) throw result.error;
      return result.notifications;
    },
    enabled: !!userId,
  });

  return { notifications: data ?? [], isLoading, error };
}

// 읽지 않은 알림 수 (30초 폴링)
export function useUnreadCount(userId: string | undefined) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["unreadCount", userId],
    queryFn: async () => {
      if (!userId) throw new Error("userId가 필요합니다.");
      const result = await fetchUnreadCount(supabase, userId);
      if (result.error) throw result.error;
      return result.count;
    },
    enabled: !!userId,
    refetchInterval: 30000,
  });

  return { unreadCount: data ?? 0, isLoading, error };
}

// 알림 읽음 처리
export function useMarkRead() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ notificationId }: { notificationId: string; userId: string }) => {
      const result = await markNotificationRead(supabase, notificationId);
      if (result.error) throw result.error;
      return result;
    },
    onSuccess: (_data, { userId }) => {
      queryClient.invalidateQueries({ queryKey: ["notifications", userId] });
      queryClient.invalidateQueries({ queryKey: ["unreadCount", userId] });
    },
  });
}

// 전체 읽음 처리
export function useMarkAllRead() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ userId }: { userId: string }) => {
      const result = await markAllNotificationsRead(supabase, userId);
      if (result.error) throw result.error;
      return result;
    },
    onSuccess: (_data, { userId }) => {
      queryClient.invalidateQueries({ queryKey: ["notifications", userId] });
      queryClient.invalidateQueries({ queryKey: ["unreadCount", userId] });
    },
  });
}
