"use client";

import Image from "next/image";
import { Card, CardContent } from "@/components/ui/card";
import { VerificationTransaction } from "@/types/warranty";
import { formatCurrency, formatDate, getConditionLabel, getConditionColor } from "@/lib/utils";
import { Star, Calendar, User, FileText } from "lucide-react";

interface PartInfoCardProps {
  transaction: VerificationTransaction;
}

export function PartInfoCard({ transaction }: PartInfoCardProps) {
  const conditionLabel = getConditionLabel(transaction.conditionScore);
  const conditionColor = getConditionColor(transaction.conditionScore);

  return (
    <Card>
      <CardContent className="p-4">
        {/* 부품 이미지 */}
        {transaction.photoUrls && transaction.photoUrls.length > 0 && (
          <div className="relative w-full h-48 mb-4 rounded-lg overflow-hidden bg-gray-100">
            <Image
              src={transaction.photoUrls[0]}
              alt={transaction.modelName}
              fill
              className="object-cover"
              sizes="(max-width: 768px) 100vw, 500px"
            />
          </div>
        )}

        {/* 부품 정보 */}
        <div className="space-y-3">
          <div>
            <h2 className="text-xl font-bold">{transaction.modelName}</h2>
            <p className="text-sm text-gray-500">
              {transaction.partCategory} / {transaction.brand}
            </p>
          </div>

          {/* 상태 점수 */}
          <div className="flex items-center gap-2">
            <Star className="h-5 w-5 text-yellow-500 fill-yellow-500" />
            <span className={`font-semibold ${conditionColor}`}>
              {conditionLabel} ({transaction.conditionScore}/10)
            </span>
          </div>

          {/* 상태 바 */}
          <div className="w-full bg-gray-100 rounded-full h-2">
            <div
              className={`h-2 rounded-full transition-all ${
                transaction.conditionScore >= 8
                  ? "bg-green-500"
                  : transaction.conditionScore >= 6
                  ? "bg-blue-500"
                  : transaction.conditionScore >= 4
                  ? "bg-yellow-500"
                  : "bg-red-500"
              }`}
              style={{ width: `${transaction.conditionScore * 10}%` }}
            />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

interface InspectionInfoProps {
  transaction: VerificationTransaction;
}

export function InspectionInfo({ transaction }: InspectionInfoProps) {
  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <h3 className="font-semibold flex items-center gap-2">
          <FileText className="h-4 w-4" />
          검수 정보
        </h3>

        <div className="space-y-2 text-sm">
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4 text-gray-500" />
            <span>검수일: {formatDate(transaction.inspectedAt)}</span>
          </div>
          <div className="flex items-center gap-2">
            <User className="h-4 w-4 text-gray-500" />
            <span>검수자: {transaction.inspectorName}</span>
          </div>
        </div>

        {transaction.inspectionNote && (
          <div className="pt-2 border-t">
            <p className="text-sm font-medium mb-1">검수 소견:</p>
            <p className="text-sm text-gray-500">
              {transaction.inspectionNote}
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

interface TransactionInfoProps {
  transaction: VerificationTransaction;
}

export function TransactionInfo({ transaction }: TransactionInfoProps) {
  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <h3 className="font-semibold">거래 정보</h3>

        <div className="space-y-2 text-sm">
          <div className="flex justify-between">
            <span className="text-gray-500">판매가</span>
            <span className="font-semibold">
              {formatCurrency(transaction.salePrice)}
            </span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-500">판매일</span>
            <span>{formatDate(transaction.saleDate)}</span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
