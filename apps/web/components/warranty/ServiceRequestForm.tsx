"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ServiceType } from "@/types/warranty";
import { createServiceRequest } from "@/lib/api/warranty";
import { Wrench, RefreshCw, Search, Upload } from "lucide-react";

const serviceRequestSchema = z.object({
  serviceType: z.enum(["repair", "replacement", "inspection"]),
  issueDescription: z.string().min(10, "증상을 10자 이상 입력해주세요"),
  customerName: z.string().min(2, "이름을 입력해주세요"),
  customerPhone: z.string().regex(/^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$/, "올바른 연락처를 입력해주세요"),
  shippingAddress: z.string().min(10, "주소를 입력해주세요"),
});

type ServiceRequestFormData = z.infer<typeof serviceRequestSchema>;

interface ServiceRequestFormProps {
  warrantyId: string;
  defaultCustomerName?: string;
  defaultCustomerPhone?: string;
  onSuccess?: (requestId: string) => void;
}

export function ServiceRequestForm({
  warrantyId,
  defaultCustomerName,
  defaultCustomerPhone,
  onSuccess,
}: ServiceRequestFormProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors },
  } = useForm<ServiceRequestFormData>({
    resolver: zodResolver(serviceRequestSchema),
    defaultValues: {
      serviceType: "repair",
      customerName: defaultCustomerName || "",
      customerPhone: defaultCustomerPhone || "",
    },
  });

  const selectedServiceType = watch("serviceType");

  const serviceTypes: { value: ServiceType; label: string; icon: typeof Wrench; description: string }[] = [
    {
      value: "repair",
      label: "수리",
      icon: Wrench,
      description: "고장 및 결함 수리",
    },
    {
      value: "replacement",
      label: "교환",
      icon: RefreshCw,
      description: "동일 제품으로 교환",
    },
    {
      value: "inspection",
      label: "점검",
      icon: Search,
      description: "상태 점검 및 진단",
    },
  ];

  const onSubmit = async (data: ServiceRequestFormData) => {
    setIsSubmitting(true);
    setError(null);

    try {
      const result = await createServiceRequest({
        warrantyId,
        serviceType: data.serviceType,
        issueDescription: data.issueDescription,
        customerName: data.customerName,
        customerPhone: data.customerPhone,
        shippingAddress: data.shippingAddress,
      });

      onSuccess?.(result.requestId);
    } catch (err: any) {
      setError(err.message || "AS 신청 중 오류가 발생했습니다");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>AS 신청</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
          {/* 서비스 유형 */}
          <div className="space-y-3">
            <Label>서비스 유형</Label>
            <RadioGroup
              value={selectedServiceType}
              onValueChange={(value) => setValue("serviceType", value as ServiceType)}
              className="grid grid-cols-3 gap-3"
            >
              {serviceTypes.map((type) => (
                <RadioGroupItem
                  key={type.value}
                  value={type.value}
                  className="flex-col items-center text-center py-3"
                >
                  <type.icon className="h-6 w-6 mb-1" />
                  <span className="font-medium">{type.label}</span>
                  <span className="text-xs text-gray-500 hidden sm:block">
                    {type.description}
                  </span>
                </RadioGroupItem>
              ))}
            </RadioGroup>
          </div>

          {/* 증상 설명 */}
          <div className="space-y-2">
            <Label required>증상 설명</Label>
            <Textarea
              placeholder="문제 증상을 상세히 설명해주세요"
              {...register("issueDescription")}
              error={errors.issueDescription?.message}
            />
          </div>

          {/* 증상 사진 */}
          <div className="space-y-2">
            <Label>증상 사진 (선택)</Label>
            <div className="border-2 border-dashed rounded-lg p-6 text-center">
              <Upload className="h-8 w-8 mx-auto text-gray-500" />
              <p className="mt-2 text-sm text-gray-500">
                사진을 드래그하거나 클릭하여 업로드
              </p>
              <p className="text-xs text-gray-500 mt-1">
                최대 5장, 각 10MB 이하
              </p>
            </div>
          </div>

          {/* 고객 정보 */}
          <div className="space-y-4">
            <h4 className="font-medium">고객 정보</h4>
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label required>이름</Label>
                <Input
                  placeholder="홍길동"
                  {...register("customerName")}
                  error={errors.customerName?.message}
                />
              </div>
              <div className="space-y-2">
                <Label required>연락처</Label>
                <Input
                  placeholder="010-1234-5678"
                  {...register("customerPhone")}
                  error={errors.customerPhone?.message}
                />
              </div>
            </div>
          </div>

          {/* 반송 주소 */}
          <div className="space-y-2">
            <Label required>반송 주소</Label>
            <Input
              placeholder="수리 완료 후 받으실 주소를 입력해주세요"
              {...register("shippingAddress")}
              error={errors.shippingAddress?.message}
            />
          </div>

          {error && (
            <div className="p-3 bg-red-50 text-red-600 rounded-lg text-sm">
              {error}
            </div>
          )}

          <Button type="submit" className="w-full" size="lg" isLoading={isSubmitting}>
            AS 신청하기
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
