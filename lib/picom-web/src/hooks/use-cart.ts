"use client";

import { useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import {
  fetchCartItems,
  addToCart,
  removeFromCart,
} from "@/lib/supabase/queries";

export function useCart(userId: string | undefined) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["cart", userId],
    queryFn: async () => {
      if (!userId) throw new Error("userId가 필요합니다.");
      const result = await fetchCartItems(supabase, userId);
      if (result.error) throw result.error;
      return result.items;
    },
    enabled: !!userId,
  });

  const items = data ?? [];

  // 총 가격 계산
  const totalPrice = useMemo(() => {
    return items.reduce((sum: number, item: Record<string, unknown>) => {
      const listing = item.listings as Record<string, unknown> | null;
      const price = (listing?.price as number) ?? 0;
      return sum + price;
    }, 0);
  }, [items]);

  return { items, isLoading, error, totalPrice };
}

export function useAddToCart() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      userId,
      listingId,
    }: {
      userId: string;
      listingId: string;
    }) => {
      const result = await addToCart(supabase, userId, listingId);
      if (result.error) throw result.error;
      return result.item;
    },
    onSuccess: (_data, { userId }) => {
      queryClient.invalidateQueries({ queryKey: ["cart", userId] });
    },
  });
}

export function useRemoveFromCart() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      cartItemId,
      userId,
    }: {
      cartItemId: string;
      userId: string;
    }) => {
      const result = await removeFromCart(supabase, cartItemId);
      if (result.error) throw result.error;
    },
    onSuccess: (_data, { userId }) => {
      queryClient.invalidateQueries({ queryKey: ["cart", userId] });
    },
  });
}
