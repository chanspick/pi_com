"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { VerificationTransaction, getDisplayName, GRADE_THRESHOLDS } from "@/types/warranty";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "https://asia-northeast3-picom-team.cloudfunctions.net/api";

type StatusFilter = "all" | "registered" | "qrGenerated" | "warrantyActive";

const statusLabels: Record<string, string> = {
  registered: "등록됨",
  qrGenerated: "QR 생성됨",
  reportIssued: "레포트 발행",
  delivered: "전달됨",
  warrantyActive: "보증 활성화",
};

const gradeColors: Record<string, string> = {
  S: "bg-indigo-500",
  A: "bg-green-500",
  B: "bg-yellow-500",
  C: "bg-orange-500",
  D: "bg-gray-500",
};

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState<VerificationTransaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<StatusFilter>("all");

  useEffect(() => {
    fetchTransactions();
  }, []);

  async function fetchTransactions() {
    try {
      setLoading(true);
      const res = await fetch(`${API_URL}/warranty/transactions`);
      if (!res.ok) throw new Error("Failed to fetch");
      const data = await res.json();
      setTransactions(data.transactions || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function generateQR(transactionId: string) {
    try {
      const res = await fetch(`${API_URL}/warranty/generate-qr/${transactionId}`, {
        method: "POST",
      });
      if (!res.ok) throw new Error("QR 생성 실패");
      await fetchTransactions();
      alert("QR 코드가 생성되었습니다.");
    } catch (err: any) {
      alert(err.message);
    }
  }

  const filteredTransactions = transactions.filter((t) => {
    if (filter === "all") return true;
    return t.status === filter;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 text-red-600 p-4 rounded-lg">
        오류: {error}
        <button onClick={fetchTransactions} className="ml-4 underline">
          다시 시도
        </button>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">거래 관리</h1>
          <p className="text-gray-500 mt-1">총 {transactions.length}건</p>
        </div>
        <Link
          href="/admin/register"
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >
          + 거래 등록
        </Link>
      </div>

      {/* Filter */}
      <div className="flex gap-2 mb-4 overflow-x-auto pb-2">
        {[
          { value: "all", label: "전체" },
          { value: "registered", label: "등록됨" },
          { value: "qrGenerated", label: "QR 생성됨" },
          { value: "warrantyActive", label: "보증 활성화" },
        ].map((f) => (
          <button
            key={f.value}
            onClick={() => setFilter(f.value as StatusFilter)}
            className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-colors ${
              filter === f.value
                ? "bg-blue-600 text-white"
                : "bg-gray-100 text-gray-700 hover:bg-gray-200"
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Transaction List */}
      {filteredTransactions.length === 0 ? (
        <div className="text-center py-12 text-gray-500">
          등록된 거래가 없습니다.
        </div>
      ) : (
        <div className="grid gap-4">
          {filteredTransactions.map((transaction) => (
            <TransactionCard
              key={transaction.transactionId}
              transaction={transaction}
              onGenerateQR={() => generateQR(transaction.transactionId)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function TransactionCard({
  transaction,
  onGenerateQR,
}: {
  transaction: VerificationTransaction;
  onGenerateQR: () => void;
}) {
  const displayName = getDisplayName(transaction);
  const grade = transaction.conditionGrade || "B";
  const gradeConfig = GRADE_THRESHOLDS[grade];

  return (
    <div className="bg-white rounded-xl border p-4 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        <div className="flex items-start gap-4">
          {/* Grade Badge */}
          <div
            className={`w-12 h-12 rounded-lg ${gradeColors[grade]} flex items-center justify-center text-white font-bold text-xl`}
          >
            {grade}
          </div>

          {/* Info */}
          <div>
            <h3 className="font-semibold text-gray-900">{displayName}</h3>
            <p className="text-sm text-gray-500 mt-1">
              {transaction.transactionId}
            </p>
            <div className="flex items-center gap-3 mt-2 text-sm">
              <span className="text-gray-600">
                스코어: <strong>{transaction.conditionScore}점</strong>
              </span>
              <span className="text-gray-600">
                기본 AS: <strong>{transaction.baseWarrantyMonths || gradeConfig?.baseWarrantyMonths || 12}개월</strong>
              </span>
              {transaction.salePrice && (
                <span className="text-gray-600">
                  판매가: <strong>₩{transaction.salePrice.toLocaleString()}</strong>
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Status & Actions */}
        <div className="flex items-center gap-2">
          <span
            className={`px-3 py-1 rounded-full text-xs font-medium ${
              transaction.status === "warrantyActive"
                ? "bg-green-100 text-green-700"
                : transaction.status === "qrGenerated"
                ? "bg-blue-100 text-blue-700"
                : "bg-gray-100 text-gray-700"
            }`}
          >
            {statusLabels[transaction.status] || transaction.status}
          </span>

          {transaction.status === "registered" && (
            <button
              onClick={onGenerateQR}
              className="px-3 py-1 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700"
            >
              QR 생성
            </button>
          )}

          {transaction.qrCodeImageUrl && (
            <a
              href={transaction.qrCodeImageUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="px-3 py-1 bg-gray-100 text-gray-700 text-sm rounded-lg hover:bg-gray-200"
            >
              QR 보기
            </a>
          )}
        </div>
      </div>

      {/* Bundle Items */}
      {transaction.transactionType === "bundle" && transaction.items && transaction.items.length > 0 && (
        <div className="mt-3 pt-3 border-t">
          <p className="text-xs text-gray-500 mb-2">부품 목록:</p>
          <div className="flex flex-wrap gap-2">
            {transaction.items.map((item, idx) => (
              <span
                key={idx}
                className="px-2 py-1 bg-gray-100 rounded text-xs text-gray-600"
              >
                {item.brand} {item.modelName}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
