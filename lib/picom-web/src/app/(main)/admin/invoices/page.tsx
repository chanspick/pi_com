"use client";

import { createClient } from "@/lib/supabase/client";
import { fetchInvoices, type InvoiceRow } from "@/lib/supabase/queries";
import { formatDate } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ExternalLink } from "lucide-react";
import { useEffect, useState } from "react";

export default function AdminInvoicesPage() {
  const supabase = createClient();
  const [invoices, setInvoices] = useState<InvoiceRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const { invoices: data } = await fetchInvoices(supabase);
      setInvoices(data);
      setLoading(false);
    }
    load();
  }, [supabase]);

  if (loading) {
    return (
      <div>
        <h1 className="text-xl font-bold mb-4">보증서 관리</h1>
        <div className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} className="h-20 w-full" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div>
      <h1 className="text-xl font-bold mb-4">보증서 관리</h1>

      {invoices.length === 0 ? (
        <p className="text-center text-muted-foreground py-8">
          보증서가 없습니다.
        </p>
      ) : (
        <Card>
          <CardHeader>
            <CardTitle className="text-sm">
              전체 {invoices.length}건
            </CardTitle>
          </CardHeader>
          <CardContent>
            {/* 데스크톱 테이블 */}
            <div className="hidden md:block overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-muted-foreground">
                    <th className="pb-2 pr-4 font-medium">보증서 번호</th>
                    <th className="pb-2 pr-4 font-medium">주문 ID</th>
                    <th className="pb-2 pr-4 font-medium">사용자 ID</th>
                    <th className="pb-2 pr-4 font-medium">보증 시작</th>
                    <th className="pb-2 pr-4 font-medium">보증 만료</th>
                    <th className="pb-2 font-medium">PDF</th>
                  </tr>
                </thead>
                <tbody>
                  {invoices.map((inv) => (
                    <tr key={inv.id} className="border-b last:border-0">
                      <td className="py-2 pr-4">
                        <Badge variant="outline">
                          {inv.invoice_number ?? "-"}
                        </Badge>
                      </td>
                      <td className="py-2 pr-4 text-xs text-muted-foreground">
                        {inv.order_id.slice(0, 8)}...
                      </td>
                      <td className="py-2 pr-4 text-xs text-muted-foreground">
                        {inv.user_id.slice(0, 8)}...
                      </td>
                      <td className="py-2 pr-4">
                        {inv.warranty_start_date
                          ? formatDate(inv.warranty_start_date)
                          : "-"}
                      </td>
                      <td className="py-2 pr-4">
                        {inv.warranty_end_date
                          ? formatDate(inv.warranty_end_date)
                          : "-"}
                      </td>
                      <td className="py-2">
                        {inv.pdf_url ? (
                          <a
                            href={inv.pdf_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 text-primary hover:underline"
                          >
                            <ExternalLink className="size-3" />
                            보기
                          </a>
                        ) : (
                          <span className="text-muted-foreground">-</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* 모바일 카드 리스트 */}
            <div className="space-y-3 md:hidden">
              {invoices.map((inv) => (
                <div
                  key={inv.id}
                  className="rounded-lg border p-3 space-y-1"
                >
                  <div className="flex items-center justify-between">
                    <Badge variant="outline">
                      {inv.invoice_number ?? "-"}
                    </Badge>
                    {inv.pdf_url ? (
                      <a
                        href={inv.pdf_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-xs text-primary hover:underline"
                      >
                        <ExternalLink className="size-3" />
                        PDF
                      </a>
                    ) : null}
                  </div>
                  <p className="text-xs text-muted-foreground">
                    주문: {inv.order_id.slice(0, 8)}... / 사용자:{" "}
                    {inv.user_id.slice(0, 8)}...
                  </p>
                  <p className="text-xs text-muted-foreground">
                    보증:{" "}
                    {inv.warranty_start_date
                      ? formatDate(inv.warranty_start_date)
                      : "-"}{" "}
                    ~{" "}
                    {inv.warranty_end_date
                      ? formatDate(inv.warranty_end_date)
                      : "-"}
                  </p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
