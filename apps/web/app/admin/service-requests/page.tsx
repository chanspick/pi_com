"use client";

import { useEffect, useState } from "react";
import { ServiceRequest } from "@/types/warranty";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "https://asia-northeast3-picom-team.cloudfunctions.net/api";

type StatusFilter = "all" | "pending" | "received" | "inProgress" | "completed";

const statusLabels: Record<string, { label: string; color: string }> = {
  pending: { label: "대기중", color: "bg-yellow-100 text-yellow-700" },
  reviewing: { label: "검토중", color: "bg-blue-100 text-blue-700" },
  approved: { label: "승인됨", color: "bg-green-100 text-green-700" },
  rejected: { label: "거절됨", color: "bg-red-100 text-red-700" },
  itemShipping: { label: "입고 배송중", color: "bg-purple-100 text-purple-700" },
  itemReceived: { label: "입고 완료", color: "bg-purple-100 text-purple-700" },
  repairing: { label: "수리중", color: "bg-orange-100 text-orange-700" },
  repaired: { label: "수리 완료", color: "bg-teal-100 text-teal-700" },
  returnShipping: { label: "반송중", color: "bg-indigo-100 text-indigo-700" },
  completed: { label: "완료", color: "bg-green-100 text-green-700" },
};

const serviceTypeLabels: Record<string, string> = {
  repair: "수리",
  replacement: "교환",
  refund: "환불",
};

export default function ServiceRequestsPage() {
  const [requests, setRequests] = useState<ServiceRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<StatusFilter>("all");
  const [selectedRequest, setSelectedRequest] = useState<ServiceRequest | null>(null);

  useEffect(() => {
    fetchRequests();
  }, []);

  async function fetchRequests() {
    try {
      setLoading(true);
      const res = await fetch(`${API_URL}/warranty/service-requests`);
      if (!res.ok) throw new Error("Failed to fetch");
      const data = await res.json();
      setRequests(data.requests || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function updateStatus(requestId: string, status: string, handlerNote?: string) {
    try {
      const res = await fetch(`${API_URL}/warranty/service-request/${requestId}/status`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          status,
          handlerId: "admin",
          handlerNote,
        }),
      });
      if (!res.ok) throw new Error("상태 업데이트 실패");
      await fetchRequests();
      setSelectedRequest(null);
      alert("상태가 업데이트되었습니다.");
    } catch (err: any) {
      alert(err.message);
    }
  }

  const filteredRequests = requests.filter((r) => {
    if (filter === "all") return true;
    return r.status === filter;
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
        <button onClick={fetchRequests} className="ml-4 underline">
          다시 시도
        </button>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">AS 요청 관리</h1>
        <p className="text-gray-500 mt-1">총 {requests.length}건</p>
      </div>

      {/* Filter */}
      <div className="flex gap-2 mb-4 overflow-x-auto pb-2">
        {[
          { value: "all", label: "전체" },
          { value: "pending", label: "대기중" },
          { value: "received", label: "접수됨" },
          { value: "inProgress", label: "처리중" },
          { value: "completed", label: "완료" },
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

      {/* Request List */}
      {filteredRequests.length === 0 ? (
        <div className="text-center py-12 text-gray-500">
          AS 요청이 없습니다.
        </div>
      ) : (
        <div className="grid gap-4">
          {filteredRequests.map((request) => (
            <div
              key={request.requestId}
              className="bg-white rounded-xl border p-4 hover:shadow-md transition-shadow cursor-pointer"
              onClick={() => setSelectedRequest(request)}
            >
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className={`px-2 py-1 rounded text-xs font-medium ${statusLabels[request.status]?.color || "bg-gray-100"}`}>
                      {statusLabels[request.status]?.label || request.status}
                    </span>
                    <span className="px-2 py-1 bg-gray-100 rounded text-xs">
                      {serviceTypeLabels[request.serviceType] || request.serviceType}
                    </span>
                  </div>
                  <p className="font-medium mt-2">{request.customerName}</p>
                  <p className="text-sm text-gray-500">{request.customerPhone}</p>
                  <p className="text-sm text-gray-600 mt-2 line-clamp-2">
                    {request.issueDescription}
                  </p>
                </div>
                <div className="text-right text-sm text-gray-500">
                  <p>{request.requestId}</p>
                  <p className="mt-1">
                    {new Date(request.createdAt).toLocaleDateString("ko-KR")}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Detail Modal */}
      {selectedRequest && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-bold">AS 요청 상세</h2>
                <button
                  onClick={() => setSelectedRequest(null)}
                  className="text-gray-500 hover:text-gray-700"
                >
                  ✕
                </button>
              </div>

              <div className="space-y-4">
                <div className="flex items-center gap-2">
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${statusLabels[selectedRequest.status]?.color}`}>
                    {statusLabels[selectedRequest.status]?.label}
                  </span>
                  <span className="px-3 py-1 bg-gray-100 rounded-full text-sm">
                    {serviceTypeLabels[selectedRequest.serviceType]}
                  </span>
                </div>

                <div className="bg-gray-50 rounded-lg p-4">
                  <p className="text-sm text-gray-500">요청 ID</p>
                  <p className="font-mono">{selectedRequest.requestId}</p>
                </div>

                <div>
                  <p className="text-sm text-gray-500">고객 정보</p>
                  <p className="font-medium">{selectedRequest.customerName}</p>
                  <p className="text-gray-600">{selectedRequest.customerPhone}</p>
                </div>

                <div>
                  <p className="text-sm text-gray-500">배송 주소</p>
                  <p className="text-gray-800">{selectedRequest.shippingAddress}</p>
                </div>

                <div>
                  <p className="text-sm text-gray-500">증상 설명</p>
                  <p className="text-gray-800 whitespace-pre-wrap">{selectedRequest.issueDescription}</p>
                </div>

                {selectedRequest.issuePhotoUrls && selectedRequest.issuePhotoUrls.length > 0 && (
                  <div>
                    <p className="text-sm text-gray-500 mb-2">첨부 사진</p>
                    <div className="flex gap-2 overflow-x-auto">
                      {selectedRequest.issuePhotoUrls.map((url, idx) => (
                        <img
                          key={idx}
                          src={url}
                          alt={`사진 ${idx + 1}`}
                          className="w-24 h-24 object-cover rounded-lg"
                        />
                      ))}
                    </div>
                  </div>
                )}

                {/* Status Actions */}
                <div className="pt-4 border-t">
                  <p className="text-sm text-gray-500 mb-2">상태 변경</p>
                  <div className="flex flex-wrap gap-2">
                    {selectedRequest.status === "pending" && (
                      <>
                        <button
                          onClick={() => updateStatus(selectedRequest.requestId, "approved")}
                          className="px-4 py-2 bg-green-600 text-white rounded-lg text-sm"
                        >
                          승인
                        </button>
                        <button
                          onClick={() => {
                            const note = prompt("거절 사유:");
                            if (note) updateStatus(selectedRequest.requestId, "rejected", note);
                          }}
                          className="px-4 py-2 bg-red-100 text-red-600 rounded-lg text-sm"
                        >
                          거절
                        </button>
                      </>
                    )}
                    {selectedRequest.status === "approved" && (
                      <button
                        onClick={() => updateStatus(selectedRequest.requestId, "itemReceived")}
                        className="px-4 py-2 bg-purple-600 text-white rounded-lg text-sm"
                      >
                        입고 완료
                      </button>
                    )}
                    {selectedRequest.status === "itemReceived" && (
                      <button
                        onClick={() => updateStatus(selectedRequest.requestId, "repairing")}
                        className="px-4 py-2 bg-orange-600 text-white rounded-lg text-sm"
                      >
                        수리 시작
                      </button>
                    )}
                    {selectedRequest.status === "repairing" && (
                      <button
                        onClick={() => updateStatus(selectedRequest.requestId, "repaired")}
                        className="px-4 py-2 bg-teal-600 text-white rounded-lg text-sm"
                      >
                        수리 완료
                      </button>
                    )}
                    {selectedRequest.status === "repaired" && (
                      <button
                        onClick={() => updateStatus(selectedRequest.requestId, "returnShipping")}
                        className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm"
                      >
                        반송 시작
                      </button>
                    )}
                    {selectedRequest.status === "returnShipping" && (
                      <button
                        onClick={() => updateStatus(selectedRequest.requestId, "completed")}
                        className="px-4 py-2 bg-green-600 text-white rounded-lg text-sm"
                      >
                        완료
                      </button>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
