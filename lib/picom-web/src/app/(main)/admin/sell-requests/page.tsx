"use client";

import { createClient } from "@/lib/supabase/client";
import {
  fetchAllSellRequests,
  updateSellRequestAdmin,
  type SellRequestRow,
} from "@/lib/supabase/queries";
import { formatDate, getCategoryLabel } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Check, X, FlaskConical, MessageSquare } from "lucide-react";
import { useEffect, useState, useCallback } from "react";

// 판매신청 상태 라벨과 배지 variant 매핑
const sellRequestStatusMap: Record<
  string,
  { label: string; variant: "default" | "secondary" | "destructive" | "outline" }
> = {
  pending: { label: "대기중", variant: "secondary" },
  reviewing: { label: "테스트중", variant: "outline" },
  approved: { label: "승인", variant: "default" },
  rejected: { label: "반려", variant: "destructive" },
  completed: { label: "완료", variant: "default" },
};

// 필터 탭 목록
const filterTabs = [
  { value: "all", label: "전체" },
  { value: "pending", label: "대기중" },
  { value: "reviewing", label: "테스트중" },
  { value: "approved", label: "승인" },
  { value: "rejected", label: "반려" },
];

export default function AdminSellRequestsPage() {
  const supabase = createClient();
  const [requests, setRequests] = useState<SellRequestRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("all");
  const [noteOpenId, setNoteOpenId] = useState<string | null>(null);
  const [noteText, setNoteText] = useState("");
  const [updating, setUpdating] = useState<string | null>(null);

  const loadRequests = useCallback(
    async (status?: string) => {
      setLoading(true);
      const { sellRequests } = await fetchAllSellRequests(
        supabase,
        status === "all" ? undefined : status
      );
      setRequests(sellRequests);
      setLoading(false);
    },
    [supabase]
  );

  useEffect(() => {
    loadRequests(activeTab);
  }, [activeTab, loadRequests]);

  // 상태 업데이트 핸들러
  async function handleUpdateStatus(
    requestId: string,
    status: string,
    adminNote?: string
  ) {
    setUpdating(requestId);
    const updates: { status: string; admin_note?: string } = { status };
    if (adminNote) updates.admin_note = adminNote;

    await updateSellRequestAdmin(supabase, requestId, updates);
    setNoteOpenId(null);
    setNoteText("");
    setUpdating(null);
    loadRequests(activeTab);
  }

  function getStatusBadge(status: string) {
    const config = sellRequestStatusMap[status] ?? {
      label: status,
      variant: "secondary" as const,
    };
    return <Badge variant={config.variant}>{config.label}</Badge>;
  }

  return (
    <div>
      <h1 className="text-xl font-bold mb-4">판매신청 관리</h1>

      <Tabs
        value={activeTab}
        onValueChange={(val) => setActiveTab(val as string)}
      >
        <TabsList className="mb-4">
          {filterTabs.map((tab) => (
            <TabsTrigger key={tab.value} value={tab.value}>
              {tab.label}
            </TabsTrigger>
          ))}
        </TabsList>

        {/* 모든 탭에 동일한 리스트를 렌더링 (데이터는 서버 필터링) */}
        {filterTabs.map((tab) => (
          <TabsContent key={tab.value} value={tab.value}>
            {loading ? (
              <div className="space-y-3">
                {Array.from({ length: 5 }).map((_, i) => (
                  <Skeleton key={i} className="h-24 w-full" />
                ))}
              </div>
            ) : requests.length === 0 ? (
              <p className="text-center text-muted-foreground py-8">
                해당 상태의 판매신청이 없습니다.
              </p>
            ) : (
              <div className="space-y-3">
                {requests.map((req) => (
                  <Card key={req.id}>
                    <CardContent className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          {getStatusBadge(req.status)}
                          <span className="text-xs text-muted-foreground">
                            {getCategoryLabel(req.category)}
                          </span>
                        </div>
                        <p className="font-medium truncate">{req.title}</p>
                        <div className="flex items-center gap-3 text-xs text-muted-foreground mt-1">
                          <span>사용자: {req.user_id.slice(0, 8)}...</span>
                          <span>{formatDate(req.created_at)}</span>
                        </div>
                        {req.admin_note && (
                          <p className="mt-1 text-xs text-muted-foreground border-l-2 border-muted pl-2">
                            관리자 메모: {req.admin_note}
                          </p>
                        )}
                      </div>

                      {/* 액션 버튼 영역 */}
                      <div className="flex flex-wrap items-center gap-2 shrink-0">
                        {req.status === "pending" && (
                          <>
                            <Button
                              size="sm"
                              variant="outline"
                              disabled={updating === req.id}
                              onClick={() =>
                                handleUpdateStatus(req.id, "reviewing")
                              }
                            >
                              <FlaskConical className="size-3.5 mr-1" />
                              테스트
                            </Button>
                            <Button
                              size="sm"
                              className="bg-green-600 text-white hover:bg-green-700"
                              disabled={updating === req.id}
                              onClick={() =>
                                handleUpdateStatus(req.id, "approved")
                              }
                            >
                              <Check className="size-3.5 mr-1" />
                              승인
                            </Button>
                            <Button
                              size="sm"
                              variant="destructive"
                              disabled={updating === req.id}
                              onClick={() => {
                                setNoteOpenId(
                                  noteOpenId === req.id ? null : req.id
                                );
                                setNoteText("");
                              }}
                            >
                              <X className="size-3.5 mr-1" />
                              반려
                            </Button>
                          </>
                        )}
                        {req.status === "reviewing" && (
                          <>
                            <Button
                              size="sm"
                              className="bg-green-600 text-white hover:bg-green-700"
                              disabled={updating === req.id}
                              onClick={() =>
                                handleUpdateStatus(req.id, "approved")
                              }
                            >
                              <Check className="size-3.5 mr-1" />
                              승인
                            </Button>
                            <Button
                              size="sm"
                              variant="destructive"
                              disabled={updating === req.id}
                              onClick={() => {
                                setNoteOpenId(
                                  noteOpenId === req.id ? null : req.id
                                );
                                setNoteText("");
                              }}
                            >
                              <X className="size-3.5 mr-1" />
                              반려
                            </Button>
                          </>
                        )}
                        {/* 관리자 메모 토글 버튼 (모든 상태) */}
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => {
                            setNoteOpenId(
                              noteOpenId === req.id ? null : req.id
                            );
                            setNoteText(req.admin_note ?? "");
                          }}
                        >
                          <MessageSquare className="size-3.5" />
                        </Button>
                      </div>
                    </CardContent>

                    {/* 관리자 메모 입력 영역 */}
                    {noteOpenId === req.id && (
                      <div className="px-4 pb-4 flex gap-2">
                        <Input
                          placeholder="관리자 메모 입력..."
                          value={noteText}
                          onChange={(e) => setNoteText(e.target.value)}
                          className="flex-1"
                        />
                        {req.status === "pending" ||
                        req.status === "reviewing" ? (
                          <Button
                            size="sm"
                            variant="destructive"
                            disabled={updating === req.id}
                            onClick={() =>
                              handleUpdateStatus(req.id, "rejected", noteText)
                            }
                          >
                            반려 확정
                          </Button>
                        ) : (
                          <Button
                            size="sm"
                            disabled={updating === req.id}
                            onClick={() =>
                              handleUpdateStatus(
                                req.id,
                                req.status,
                                noteText
                              )
                            }
                          >
                            메모 저장
                          </Button>
                        )}
                      </div>
                    )}
                  </Card>
                ))}
              </div>
            )}
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
}
