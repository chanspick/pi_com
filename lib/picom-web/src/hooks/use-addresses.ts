"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import {
  fetchAddresses,
  createAddress,
  updateAddress,
  deleteAddress,
  AddressRow,
} from "@/lib/supabase/queries";

export function useAddresses(userId: string | undefined) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["addresses", userId],
    queryFn: async () => {
      const result = await fetchAddresses(supabase, userId!);
      if (result.error) throw result.error;
      return result.addresses;
    },
    enabled: !!userId,
  });
}

export function useCreateAddress() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (address: {
      user_id: string;
      recipient_name: string;
      phone: string;
      postal_code: string;
      address_line1: string;
      address_line2?: string;
      is_default?: boolean;
    }) => {
      const result = await createAddress(supabase, address);
      if (result.error) throw result.error;
      return result.address;
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["addresses", variables.user_id],
      });
    },
  });
}

export function useUpdateAddress() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      addressId,
      userId,
      updates,
    }: {
      addressId: string;
      userId: string;
      updates: Partial<{
        recipient_name: string;
        phone: string;
        postal_code: string;
        address_line1: string;
        address_line2: string;
        is_default: boolean;
      }>;
    }) => {
      const result = await updateAddress(supabase, addressId, userId, updates);
      if (result.error) throw result.error;
      return result.address;
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["addresses", variables.userId],
      });
    },
  });
}

export function useDeleteAddress() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      addressId,
      userId,
    }: {
      addressId: string;
      userId: string;
    }) => {
      const result = await deleteAddress(supabase, addressId);
      if (result.error) throw result.error;
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["addresses", variables.userId],
      });
    },
  });
}

export type { AddressRow };
