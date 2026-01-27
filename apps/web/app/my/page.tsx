"use client";

import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth/AuthContext";
import { getMyWarranties } from "@/lib/api/warranty";
import { WarrantyCard } from "@/components/warranty/WarrantyCard";
import { LoginPrompt } from "@/components/auth/LoginPrompt";
import { Shield, Loader2, Inbox } from "lucide-react";

export default function MyWarrantiesPage() {
  const { user, loading: authLoading, getIdToken } = useAuth();

  const {
    data,
    isLoading,
    error,
  } = useQuery({
    queryKey: ["my-warranties", user?.uid],
    queryFn: async () => {
      const token = await getIdToken();
      if (!token) throw new Error("Not authenticated");
      return getMyWarranties(token);
    },
    enabled: !!user,
  });

  if (authLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-lg">
        <div className="text-center mb-6">
          <Shield className="h-12 w-12 text-blue-600 mx-auto" />
          <h1 className="mt-3 text-xl font-bold">내 보증 목록</h1>
          <p className="mt-2 text-gray-500">
            보증 목록을 확인하려면 로그인이 필요합니다.
          </p>
        </div>
        <LoginPrompt
          redirectPath="/my"
          message="내 보증 목록을 확인하려면 로그인해주세요."
        />
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-lg">
      <div className="flex items-center gap-3 mb-6">
        <Shield className="h-6 w-6 text-blue-600" />
        <h1 className="text-xl font-bold">내 보증 목록</h1>
      </div>

      {isLoading && (
        <div className="flex flex-col items-center justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
          <p className="mt-4 text-gray-500">불러오는 중...</p>
        </div>
      )}

      {error && (
        <div className="bg-red-50 rounded-xl p-4 text-center">
          <p className="text-red-600 text-sm">
            보증 목록을 불러오는데 실패했습니다.
          </p>
        </div>
      )}

      {data && data.warranties.length === 0 && (
        <div className="flex flex-col items-center justify-center py-12">
          <Inbox className="h-12 w-12 text-gray-300" />
          <p className="mt-4 text-gray-500">등록된 보증이 없습니다.</p>
          <p className="mt-1 text-gray-400 text-sm">
            QR 코드를 스캔하여 보증을 등록해주세요.
          </p>
        </div>
      )}

      {data && data.warranties.length > 0 && (
        <div className="space-y-3">
          {data.warranties.map((warranty) => (
            <WarrantyCard key={warranty.transactionId} warranty={warranty} />
          ))}
        </div>
      )}
    </div>
  );
}
