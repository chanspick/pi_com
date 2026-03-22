"use client";

import Link from "next/link";
import { useAuth } from "@/hooks/use-auth";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import {
  ArrowLeft,
  Pencil,
  Bell,
  Shield,
  Trash2,
  ChevronRight,
} from "lucide-react";

const settingsItems = [
  {
    title: "프로필 수정",
    description: "닉네임, 프로필 사진 등을 변경합니다",
    href: "/my/profile/edit",
    icon: Pencil,
  },
  {
    title: "가격 알림 관리",
    description: "부품 가격 알림을 설정하고 관리합니다",
    href: "/my/alerts",
    icon: Bell,
  },
  {
    title: "배송지 관리",
    description: "배송 주소를 추가하거나 수정합니다",
    href: "/my/addresses",
    icon: Shield,
  },
];

export default function SettingsPage() {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-8">
        <div className="h-8 w-32 bg-muted animate-pulse rounded mb-6" />
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-20 bg-muted animate-pulse rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      <div className="mb-6 flex items-center gap-3">
        <Link href="/my">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <h1 className="text-xl font-bold">설정</h1>
      </div>

      <div className="space-y-3">
        {settingsItems.map((item) => (
          <Link key={item.href} href={item.href}>
            <Card className="hover:border-primary/30 hover:shadow-sm transition-all cursor-pointer mb-3">
              <CardContent className="flex items-center gap-4 py-4">
                <div className="w-10 h-10 rounded-xl bg-primary/5 flex items-center justify-center shrink-0">
                  <item.icon className="h-5 w-5 text-primary/70" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-[14px] font-semibold">{item.title}</p>
                  <p className="text-[12px] text-muted-foreground">
                    {item.description}
                  </p>
                </div>
                <ChevronRight className="h-4 w-4 text-muted-foreground shrink-0" />
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      <Separator className="my-6" />

      {/* 위험 영역 */}
      <div className="space-y-3">
        <h2 className="text-[14px] font-semibold text-destructive">
          위험 영역
        </h2>
        <Link href="/my/account/delete">
          <Card className="border-destructive/20 hover:border-destructive/40 transition-all cursor-pointer">
            <CardContent className="flex items-center gap-4 py-4">
              <div className="w-10 h-10 rounded-xl bg-destructive/5 flex items-center justify-center shrink-0">
                <Trash2 className="h-5 w-5 text-destructive/70" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-[14px] font-semibold text-destructive">
                  계정 삭제
                </p>
                <p className="text-[12px] text-muted-foreground">
                  계정과 모든 데이터를 영구적으로 삭제합니다
                </p>
              </div>
              <ChevronRight className="h-4 w-4 text-muted-foreground shrink-0" />
            </CardContent>
          </Card>
        </Link>
      </div>
    </div>
  );
}
