"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { fetchFavorites, toggleFavorite } from "@/lib/supabase/queries";

export function useFavorites(userId: string | undefined) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["favorites", userId],
    queryFn: async () => {
      if (!userId) throw new Error("userId가 필요합니다.");
      const result = await fetchFavorites(supabase, userId);
      if (result.error) throw result.error;
      return result.favorites;
    },
    enabled: !!userId,
  });

  return { favorites: data ?? [], isLoading, error };
}

export function useToggleFavorite() {
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
      const result = await toggleFavorite(supabase, userId, listingId);
      if (result.error) throw result.error;
      return result;
    },
    onMutate: async ({ userId, listingId }) => {
      // 옵티미스틱 업데이트: 기존 쿼리 취소
      await queryClient.cancelQueries({ queryKey: ["favorites", userId] });

      // 이전 데이터 스냅샷
      const previousFavorites = queryClient.getQueryData(["favorites", userId]);

      // 옵티미스틱하게 즐겨찾기 목록에서 제거
      queryClient.setQueryData(
        ["favorites", userId],
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (old: any[] | undefined) =>
          old
            ? old.filter(
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                (fav: any) => fav.listing_id !== listingId
              )
            : []
      );

      return { previousFavorites };
    },
    onError: (_err, { userId }, context) => {
      // 에러 시 이전 데이터로 롤백
      if (context?.previousFavorites) {
        queryClient.setQueryData(
          ["favorites", userId],
          context.previousFavorites
        );
      }
    },
    onSettled: (_data, _error, { userId }) => {
      // 성공/실패 무관하게 쿼리 무효화
      queryClient.invalidateQueries({ queryKey: ["favorites", userId] });
    },
  });
}
