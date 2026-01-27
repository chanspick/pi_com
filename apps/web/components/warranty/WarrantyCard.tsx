"use client";

import Link from "next/link";
import { GradeBadge } from "./GradeBadge";
import { MyWarrantyItem } from "@/lib/api/warranty";
import { ConditionGrade } from "@/types/warranty";
import { Shield, Package, ExternalLink, Download } from "lucide-react";

interface WarrantyCardProps {
  warranty: MyWarrantyItem;
}

export function WarrantyCard({ warranty }: WarrantyCardProps) {
  const isBundle = warranty.transactionType === "bundle";
  const displayName = isBundle
    ? warranty.bundleName || "조립 PC 세트"
    : `${warranty.brand || ""} ${warranty.modelName || ""}`.trim() || "제품";

  const statusLabel: Record<string, { text: string; color: string }> = {
    active: { text: "보증 유효", color: "text-green-600 bg-green-50" },
    expired: { text: "만료됨", color: "text-gray-600 bg-gray-100" },
    claimed: { text: "AS 접수", color: "text-orange-600 bg-orange-50" },
    completed: { text: "AS 완료", color: "text-blue-600 bg-blue-50" },
    pending: { text: "대기 중", color: "text-yellow-600 bg-yellow-50" },
  };

  const status = warranty.warrantyStatus
    ? statusLabel[warranty.warrantyStatus] || { text: warranty.warrantyStatus, color: "text-gray-500 bg-gray-50" }
    : { text: "미활성", color: "text-gray-500 bg-gray-50" };

  return (
    <div className="bg-white rounded-xl border p-4 hover:shadow-sm transition-shadow">
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-2">
          <Package className="h-5 w-5 text-gray-400" />
          <span className="font-medium text-sm">{displayName}</span>
        </div>
        <span className={`text-xs font-medium px-2 py-1 rounded-full ${status.color}`}>
          {status.text}
        </span>
      </div>

      {warranty.conditionGrade && (
        <div className="mb-2">
          <GradeBadge grade={warranty.conditionGrade as ConditionGrade} />
        </div>
      )}

      <div className="text-sm text-gray-500 space-y-1">
        {warranty.salePrice && (
          <p>판매가: {"\u20A9"}{warranty.salePrice.toLocaleString()}</p>
        )}
        <p>
          보증: {warranty.totalWarrantyMonths || warranty.baseWarrantyMonths}개월
          {warranty.warrantyId && (
            <span className="inline-flex items-center gap-1 ml-2">
              <Shield className="h-3 w-3 text-green-500" />
            </span>
          )}
        </p>
      </div>

      <div className="flex items-center gap-2 mt-3 pt-3 border-t">
        <Link
          href={`/warranty/${warranty.qrCode}`}
          className="flex items-center gap-1 text-blue-600 text-sm hover:underline"
        >
          상세보기 <ExternalLink className="h-3 w-3" />
        </Link>
        {warranty.warrantyPdfUrl && (
          <a
            href={warranty.warrantyPdfUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1 text-gray-500 text-sm hover:text-gray-700 ml-auto"
          >
            <Download className="h-3 w-3" /> PDF
          </a>
        )}
      </div>
    </div>
  );
}
