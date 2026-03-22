"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { fetchProfile, updateProfile } from "@/lib/supabase/queries";

export function useProfile(userId: string | undefined) {
  const supabase = createClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ["profile", userId],
    queryFn: async () => {
      if (!userId) throw new Error("userId가 필요합니다.");
      const result = await fetchProfile(supabase, userId);
      if (result.error) throw result.error;
      return result.profile;
    },
    enabled: !!userId,
  });

  return { profile: data ?? null, isLoading, error };
}

export function useUpdateProfile() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      userId,
      updates,
    }: {
      userId: string;
      updates: { display_name?: string; avatar_url?: string };
    }) => {
      const result = await updateProfile(supabase, userId, updates);
      if (result.error) throw result.error;
      return result.profile;
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ["profile", variables.userId] });
    },
  });
}
