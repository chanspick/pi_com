"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { WarrantyPlan, WARRANTY_RATES } from "@/types/warranty";
import { formatCurrency } from "@/lib/utils";
import { Shield, Check } from "lucide-react";

interface WarrantyPlanSelectorProps {
  salePrice: number;
  selectedPlan?: WarrantyPlan;
  onPlanChange: (plan: WarrantyPlan) => void;
}

export function WarrantyPlanSelector({
  salePrice,
  selectedPlan,
  onPlanChange,
}: WarrantyPlanSelectorProps) {
  const plans: { value: WarrantyPlan; label: string; description: string }[] = [
    {
      value: "1year",
      label: "1년 보증",
      description: "기본적인 AS 보증 서비스",
    },
    {
      value: "2year",
      label: "2년 보증",
      description: "장기 AS 보증 서비스",
    },
  ];

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-lg">
          <Shield className="h-5 w-5 text-blue-600" />
          AS 보증 가입
        </CardTitle>
      </CardHeader>
      <CardContent>
        <RadioGroup
          value={selectedPlan}
          onValueChange={(value) => onPlanChange(value as WarrantyPlan)}
        >
          {plans.map((plan) => {
            const rate = WARRANTY_RATES[plan.value];
            const price = Math.round(salePrice * rate.rate);

            return (
              <RadioGroupItem key={plan.value} value={plan.value}>
                <div className="flex-1">
                  <div className="flex items-center justify-between">
                    <span className="font-semibold">{plan.label}</span>
                    <span className="font-bold text-blue-600">
                      {formatCurrency(price)}
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-sm text-gray-500">
                    <span>{plan.description}</span>
                    <span>{Math.round(rate.rate * 100)}%</span>
                  </div>
                </div>
              </RadioGroupItem>
            );
          })}
        </RadioGroup>

        <div className="mt-4 p-3 bg-gray-100 rounded-lg">
          <h4 className="font-medium text-sm mb-2">보증 혜택</h4>
          <ul className="space-y-1 text-sm text-gray-500">
            <li className="flex items-center gap-2">
              <Check className="h-4 w-4 text-green-500" />
              무상 수리 서비스
            </li>
            <li className="flex items-center gap-2">
              <Check className="h-4 w-4 text-green-500" />
              부품 교환 서비스
            </li>
            <li className="flex items-center gap-2">
              <Check className="h-4 w-4 text-green-500" />
              우선 점검 서비스
            </li>
          </ul>
        </div>
      </CardContent>
    </Card>
  );
}
