"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ServiceRequest, ServiceRequestStatus } from "@/types/warranty";
import { formatDate, getStatusLabel, getServiceTypeLabel } from "@/lib/utils";
import {
  CheckCircle2,
  Clock,
  Package,
  Search,
  Truck,
  Wrench,
  XCircle,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface ServiceTimelineProps {
  requests: ServiceRequest[];
}

const statusSteps: { status: ServiceRequestStatus; label: string; icon: typeof Clock }[] = [
  { status: "pending", label: "접수", icon: Clock },
  { status: "reviewing", label: "검토", icon: Search },
  { status: "approved", label: "승인", icon: CheckCircle2 },
  { status: "itemShipping", label: "발송", icon: Truck },
  { status: "itemReceived", label: "수령", icon: Package },
  { status: "repairing", label: "수리", icon: Wrench },
  { status: "repaired", label: "완료", icon: CheckCircle2 },
  { status: "returnShipping", label: "반송", icon: Truck },
  { status: "completed", label: "종료", icon: CheckCircle2 },
];

function getStatusIndex(status: ServiceRequestStatus): number {
  if (status === "rejected") return -1;
  const index = statusSteps.findIndex((s) => s.status === status);
  return index;
}

export function ServiceTimeline({ requests }: ServiceTimelineProps) {
  if (requests.length === 0) {
    return (
      <Card>
        <CardContent className="p-6 text-center text-gray-500">
          AS 신청 내역이 없습니다.
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {requests.map((request) => (
        <ServiceRequestCard key={request.requestId} request={request} />
      ))}
    </div>
  );
}

interface ServiceRequestCardProps {
  request: ServiceRequest;
}

function ServiceRequestCard({ request }: ServiceRequestCardProps) {
  const isRejected = request.status === "rejected";
  const currentStepIndex = getStatusIndex(request.status);

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-base">
            {getServiceTypeLabel(request.serviceType)} 요청
          </CardTitle>
          <span
            className={cn(
              "text-sm font-medium px-2 py-1 rounded",
              isRejected
                ? "bg-red-50 text-red-600"
                : request.status === "completed"
                ? "bg-green-100 text-green-700"
                : "bg-blue-50 text-blue-600"
            )}
          >
            {getStatusLabel(request.status)}
          </span>
        </div>
        <p className="text-sm text-gray-500">
          신청일: {formatDate(request.requestedAt)}
        </p>
      </CardHeader>
      <CardContent>
        {/* 진행 상태 표시 */}
        {!isRejected && (
          <div className="mb-4">
            <div className="flex items-center justify-between mb-2">
              {statusSteps.slice(0, 5).map((step, index) => {
                const isActive = index <= currentStepIndex;
                const isCurrent = index === currentStepIndex;
                const Icon = step.icon;

                return (
                  <div
                    key={step.status}
                    className={cn(
                      "flex flex-col items-center",
                      isActive ? "text-blue-600" : "text-gray-500"
                    )}
                  >
                    <div
                      className={cn(
                        "w-8 h-8 rounded-full flex items-center justify-center mb-1",
                        isActive ? "bg-blue-600 text-white" : "bg-gray-100",
                        isCurrent && "ring-2 ring-blue-600 ring-offset-2"
                      )}
                    >
                      <Icon className="h-4 w-4" />
                    </div>
                    <span className="text-xs">{step.label}</span>
                  </div>
                );
              })}
            </div>
            <div className="relative h-1 bg-gray-100 rounded-full">
              <div
                className="absolute h-1 bg-blue-600 rounded-full transition-all"
                style={{
                  width: `${Math.max(0, (currentStepIndex / 4) * 100)}%`,
                }}
              />
            </div>
          </div>
        )}

        {/* 거부된 경우 */}
        {isRejected && (
          <div className="flex items-center gap-2 p-3 bg-red-50 rounded-lg mb-4">
            <XCircle className="h-5 w-5 text-red-600" />
            <div>
              <p className="font-medium text-red-600">요청이 거부되었습니다</p>
              {request.handlerNote && (
                <p className="text-sm text-gray-500">
                  사유: {request.handlerNote}
                </p>
              )}
            </div>
          </div>
        )}

        {/* 증상 설명 */}
        <div className="space-y-2">
          <h4 className="font-medium text-sm">증상 설명</h4>
          <p className="text-sm text-gray-500 bg-gray-100 p-3 rounded">
            {request.issueDescription}
          </p>
        </div>

        {/* 배송 정보 */}
        {(request.inboundTrackingNumber || request.outboundTrackingNumber) && (
          <div className="mt-4 space-y-2">
            <h4 className="font-medium text-sm">배송 정보</h4>
            <div className="text-sm space-y-1">
              {request.inboundTrackingNumber && (
                <p>
                  <span className="text-gray-500">발송 송장:</span>{" "}
                  {request.inboundTrackingNumber}
                </p>
              )}
              {request.outboundTrackingNumber && (
                <p>
                  <span className="text-gray-500">반송 송장:</span>{" "}
                  {request.outboundTrackingNumber}
                </p>
              )}
            </div>
          </div>
        )}

        {/* 완료된 경우 */}
        {request.status === "completed" && request.completedAt && (
          <div className="mt-4 flex items-center gap-2 p-3 bg-green-50 rounded-lg">
            <CheckCircle2 className="h-5 w-5 text-green-600" />
            <div>
              <p className="font-medium text-green-700">AS가 완료되었습니다</p>
              <p className="text-sm text-green-600">
                완료일: {formatDate(request.completedAt)}
              </p>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
