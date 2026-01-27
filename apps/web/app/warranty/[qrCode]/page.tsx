"use client";

import { use, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import {
  PartInfoCard,
} from "@/components/warranty/PartInfoCard";
import { BundleItemList } from "@/components/warranty/BundleItemList";
import { GradeBadge } from "@/components/warranty/GradeBadge";
import { getTransactionByQR, activateWarranty, linkUserToWarranty } from "@/lib/api/warranty";
import { isBundle, getDisplayName } from "@/types/warranty";
import { useAuth } from "@/lib/auth/AuthContext";
import { LoginPrompt } from "@/components/auth/LoginPrompt";
import {
  Shield, AlertCircle, Loader2, CheckCircle, Package,
  Clock, CreditCard, UserPlus, Download, ExternalLink,
} from "lucide-react";

interface PageProps {
  params: Promise<{ qrCode: string }>;
}

export default function WarrantyLandingPage({ params }: PageProps) {
  const { qrCode } = use(params);
  const queryClient = useQueryClient();
  const { user, getIdToken } = useAuth();
  const [customerName, setCustomerName] = useState("");
  const [customerPhone, setCustomerPhone] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [activated, setActivated] = useState(false);
  const [showLogin, setShowLogin] = useState(false);
  const [linked, setLinked] = useState(false);

  const {
    data: transaction,
    isLoading,
    error,
  } = useQuery({
    queryKey: ["transaction", qrCode],
    queryFn: () => getTransactionByQR(qrCode),
  });

  const activateMutation = useMutation({
    mutationFn: () => activateWarranty({
      qrCode,
      customerName,
      customerPhone,
    }),
    onSuccess: () => {
      setActivated(true);
      queryClient.invalidateQueries({ queryKey: ["transaction", qrCode] });
    },
  });

  const linkMutation = useMutation({
    mutationFn: async () => {
      const token = await getIdToken();
      if (!token) throw new Error("로그인이 필요합니다.");
      return linkUserToWarranty(qrCode, token);
    },
    onSuccess: () => {
      setLinked(true);
    },
  });

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
        <p className="mt-4 text-gray-500">거래 정보를 불러오는 중...</p>
      </div>
    );
  }

  if (error || !transaction) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] px-4">
        <AlertCircle className="h-12 w-12 text-red-500" />
        <h1 className="mt-4 text-xl font-bold">거래 정보를 찾을 수 없습니다</h1>
        <p className="mt-2 text-gray-500 text-center">
          유효하지 않은 QR 코드이거나 거래 정보가 존재하지 않습니다.
        </p>
      </div>
    );
  }

  const isBundleType = isBundle(transaction);
  const displayName = getDisplayName(transaction);
  const warrantyMonths = transaction.baseWarrantyMonths || 12;

  // 이미 보증이 활성화된 경우 또는 방금 활성화한 경우
  if (transaction.warrantyId || activated) {
    const saleDate = transaction.saleDate as string | { _seconds: number };
    const warrantyStartDate = saleDate
      ? new Date(typeof saleDate === "object" && "_seconds" in saleDate ? saleDate._seconds * 1000 : saleDate)
      : new Date();
    const warrantyEndDate = new Date(warrantyStartDate);
    warrantyEndDate.setMonth(warrantyEndDate.getMonth() + warrantyMonths);

    const now = new Date();
    const isExpired = now > warrantyEndDate;
    const daysRemaining = Math.max(0, Math.ceil((warrantyEndDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)));

    return (
      <div className="container mx-auto px-4 py-8 max-w-lg">
        {/* 거래 완료 헤더 */}
        <div className="text-center mb-8">
          <CheckCircle className="h-16 w-16 text-green-500 mx-auto" />
          <h1 className="mt-4 text-2xl font-bold">거래 완료</h1>
          <p className="mt-2 text-gray-500">
            AS 보증이 활성화되었습니다.
          </p>
        </div>

        {/* 제품 정보 */}
        <div className="bg-white rounded-xl border p-4 mb-4">
          <div className="flex items-center gap-3 mb-3">
            <Package className="h-5 w-5 text-gray-400" />
            <span className="font-medium">{displayName}</span>
          </div>
          {transaction.conditionGrade && (
            <div className="mb-2">
              <GradeBadge grade={transaction.conditionGrade} />
            </div>
          )}
          {transaction.salePrice && (
            <p className="text-gray-600">
              판매가: <strong>{"\u20A9"}{transaction.salePrice.toLocaleString()}</strong>
            </p>
          )}
        </div>

        {/* 기본 보증 정보 */}
        <div className="bg-blue-50 rounded-xl p-4 mb-4">
          <div className="flex items-center gap-2 mb-2">
            <Shield className="h-5 w-5 text-blue-600" />
            <span className="font-semibold text-blue-900">기본 보증 ({warrantyMonths}개월)</span>
          </div>
          {isExpired ? (
            <p className="text-red-600 text-sm">
              기본 보증 기간이 만료되었습니다.
            </p>
          ) : (
            <p className="text-blue-700 text-sm">
              남은 기간: <strong>{daysRemaining}일</strong>
            </p>
          )}
        </div>

        {/* PDF 다운로드 */}
        {transaction.warrantyPdfUrl && (
          <a
            href={transaction.warrantyPdfUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 bg-white rounded-xl border p-4 mb-4 hover:bg-gray-50 transition-colors"
          >
            <Download className="h-5 w-5 text-blue-600" />
            <span className="text-blue-600 font-medium">보증서 PDF 다운로드</span>
            <ExternalLink className="h-4 w-4 text-blue-400 ml-auto" />
          </a>
        )}

        {/* 추가 보증 구매 */}
        {!isExpired && (
          <div className="bg-white rounded-xl border p-4 mb-4">
            <div className="flex items-center gap-2 mb-3">
              <CreditCard className="h-5 w-5 text-gray-400" />
              <span className="font-semibold">추가 보증 구매</span>
            </div>
            <p className="text-sm text-gray-500 mb-4">
              기본 보증 기간 내에만 구매 가능합니다.
            </p>
            <div className="space-y-2">
              <a
                href={`/warranty/purchase/${qrCode}?plan=1year`}
                className="block w-full py-3 px-4 bg-gray-100 rounded-lg text-center hover:bg-gray-200 transition-colors"
              >
                +1년 추가 - <strong>{"\u20A9"}{Math.round((transaction.salePrice || 0) * 0.1).toLocaleString()}</strong>
              </a>
              <a
                href={`/warranty/purchase/${qrCode}?plan=2year`}
                className="block w-full py-3 px-4 bg-gray-100 rounded-lg text-center hover:bg-gray-200 transition-colors"
              >
                +2년 추가 - <strong>{"\u20A9"}{Math.round((transaction.salePrice || 0) * 0.2).toLocaleString()}</strong>
              </a>
            </div>
          </div>
        )}

        {isExpired && (
          <div className="bg-gray-100 rounded-xl p-4 text-center mb-4">
            <Clock className="h-8 w-8 text-gray-400 mx-auto mb-2" />
            <p className="text-gray-600 text-sm">
              기본 보증 기간이 만료되어<br />추가 보증을 구매할 수 없습니다.
            </p>
          </div>
        )}

        {/* 내 계정으로 등록 */}
        {!linked && !showLogin && (
          <div className="bg-white rounded-xl border p-4">
            <div className="flex items-center gap-2 mb-3">
              <UserPlus className="h-5 w-5 text-gray-400" />
              <span className="font-semibold">내 계정으로 등록</span>
            </div>
            <p className="text-sm text-gray-500 mb-3">
              로그인 후 보증을 내 계정에 연결하면 보증 관리가 편리합니다.
            </p>
            {user ? (
              <Button
                onClick={() => linkMutation.mutate()}
                disabled={linkMutation.isPending}
                className="w-full"
              >
                {linkMutation.isPending ? (
                  <><Loader2 className="h-4 w-4 animate-spin mr-2" />연결 중...</>
                ) : (
                  "내 계정에 등록하기"
                )}
              </Button>
            ) : (
              <Button
                onClick={() => setShowLogin(true)}
                variant="outline"
                className="w-full"
              >
                로그인하여 등록하기
              </Button>
            )}
            {linkMutation.isError && (
              <p className="mt-2 text-sm text-red-600 text-center">
                {(linkMutation.error as Error)?.message || "연결에 실패했습니다."}
              </p>
            )}
          </div>
        )}

        {showLogin && !user && (
          <LoginPrompt
            redirectPath={`/warranty/${qrCode}`}
            onClose={() => setShowLogin(false)}
            message="보증을 내 계정에 연결하려면 로그인이 필요합니다."
          />
        )}

        {(linked || linkMutation.isSuccess) && (
          <div className="bg-green-50 rounded-xl p-4 text-center">
            <CheckCircle className="h-8 w-8 text-green-500 mx-auto mb-2" />
            <p className="text-green-700 font-medium">내 계정에 등록되었습니다!</p>
            <a href="/my" className="text-green-600 text-sm hover:underline mt-1 inline-block">
              내 보증 목록 보기
            </a>
          </div>
        )}
      </div>
    );
  }

  // 아직 활성화되지 않은 경우
  return (
    <div className="container mx-auto px-4 py-8 max-w-lg">
      {/* 헤더 */}
      <div className="text-center mb-6">
        <Shield className="h-12 w-12 text-blue-600 mx-auto" />
        <h1 className="mt-3 text-xl font-bold">PiComputer AS 보증</h1>
      </div>

      {/* 제품 정보 */}
      <PartInfoCard transaction={transaction} />

      {isBundleType && transaction.items && (
        <div className="mt-4">
          <BundleItemList items={transaction.items} />
        </div>
      )}

      {/* 보증 안내 */}
      <div className="mt-6 bg-blue-50 rounded-xl p-4">
        <h3 className="font-semibold text-blue-900 mb-2">기본 보증 안내</h3>
        <ul className="text-sm text-blue-700 space-y-1">
          <li>{"• "}기본 보증 기간: <strong>{warrantyMonths}개월</strong></li>
          <li>{"• "}보증 기간 내 추가 보증 구매 가능</li>
          <li>{"• "}+1년: 판매가의 10%</li>
          <li>{"• "}+2년: 판매가의 20%</li>
        </ul>
      </div>

      {/* 활성화 폼 */}
      {!showForm ? (
        <Button
          onClick={() => setShowForm(true)}
          className="w-full mt-6 py-6 text-lg"
        >
          보증 활성화하기
        </Button>
      ) : (
        <div className="mt-6 bg-white rounded-xl border p-4">
          <h3 className="font-semibold mb-4">고객 정보 입력</h3>
          <div className="space-y-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                이름 *
              </label>
              <input
                type="text"
                value={customerName}
                onChange={(e) => setCustomerName(e.target.value)}
                className="w-full border rounded-lg px-3 py-2"
                placeholder="홍길동"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                연락처 *
              </label>
              <input
                type="tel"
                value={customerPhone}
                onChange={(e) => setCustomerPhone(e.target.value)}
                className="w-full border rounded-lg px-3 py-2"
                placeholder="010-1234-5678"
              />
            </div>
          </div>
          <Button
            onClick={() => activateMutation.mutate()}
            disabled={!customerName || !customerPhone || activateMutation.isPending}
            className="w-full mt-4 py-6"
          >
            {activateMutation.isPending ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin mr-2" />
                처리 중...
              </>
            ) : (
              "확인"
            )}
          </Button>
          {activateMutation.isError && (
            <p className="mt-2 text-sm text-red-600 text-center">
              오류가 발생했습니다. 다시 시도해주세요.
            </p>
          )}
        </div>
      )}
    </div>
  );
}
