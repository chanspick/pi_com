"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Package } from "lucide-react";

export default function AdminListingsPage() {
  return (
    <div>
      <h1 className="text-xl font-bold mb-4">매물 관리</h1>
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-sm">
            <Package className="size-4" />
            매물 관리
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-muted-foreground">
            매물 관리 기능은 준비 중입니다.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
