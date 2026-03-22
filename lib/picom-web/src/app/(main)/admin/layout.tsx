"use client";

import { useAuth } from "@/hooks/use-auth";
import { createClient } from "@/lib/supabase/client";
import { fetchProfile, type ProfileRow } from "@/lib/supabase/queries";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard,
  Package,
  FileText,
  ShoppingCart,
  RotateCcw,
  ScrollText,
  Menu,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Sheet,
  SheetTrigger,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Separator } from "@/components/ui/separator";

// 관리자 네비게이션 메뉴 항목
const adminNavItems = [
  { href: "/admin", label: "대시보드", icon: LayoutDashboard },
  { href: "/admin/listings", label: "매물 관리", icon: Package },
  { href: "/admin/sell-requests", label: "판매신청", icon: FileText },
  { href: "/admin/orders", label: "주문 관리", icon: ShoppingCart },
  { href: "/admin/refunds", label: "환불 관리", icon: RotateCcw },
  { href: "/admin/invoices", label: "보증서", icon: ScrollText },
];

function NavLink({
  href,
  label,
  icon: Icon,
  isActive,
  onClick,
}: {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  isActive: boolean;
  onClick?: () => void;
}) {
  return (
    <Link
      href={href}
      onClick={onClick}
      className={cn(
        "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
        isActive
          ? "bg-primary/10 text-primary"
          : "text-muted-foreground hover:bg-muted hover:text-foreground"
      )}
    >
      <Icon className="size-4 shrink-0" />
      {label}
    </Link>
  );
}

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user, loading: authLoading } = useAuth();
  const [profile, setProfile] = useState<ProfileRow | null>(null);
  const [profileLoading, setProfileLoading] = useState(true);
  const [mobileOpen, setMobileOpen] = useState(false);
  const pathname = usePathname();
  const router = useRouter();
  const supabase = createClient();

  useEffect(() => {
    if (authLoading) return;
    if (!user) {
      router.replace("/login");
      return;
    }

    async function loadProfile() {
      const { profile: p } = await fetchProfile(supabase, user!.id);
      setProfile(p);
      setProfileLoading(false);
    }
    loadProfile();
  }, [user, authLoading, supabase, router]);

  // 로딩 중
  if (authLoading || profileLoading) {
    return (
      <div className="container mx-auto max-w-7xl px-4 py-8">
        <div className="flex gap-6">
          <div className="hidden w-56 shrink-0 md:block">
            <Skeleton className="h-8 w-32 mb-4" />
            {Array.from({ length: 6 }).map((_, i) => (
              <Skeleton key={i} className="h-9 w-full mb-1" />
            ))}
          </div>
          <div className="flex-1">
            <Skeleton className="h-8 w-48 mb-4" />
            <Skeleton className="h-64 w-full" />
          </div>
        </div>
      </div>
    );
  }

  // 관리자 권한 검증
  if (!user || !profile?.is_admin) {
    return (
      <div className="container mx-auto max-w-7xl px-4 py-16 text-center">
        <h1 className="text-xl font-bold text-destructive mb-2">
          접근 권한이 없습니다
        </h1>
        <p className="text-muted-foreground mb-4">
          관리자만 접근할 수 있는 페이지입니다.
        </p>
        <Button variant="outline" onClick={() => router.replace("/")}>
          홈으로 돌아가기
        </Button>
      </div>
    );
  }

  // 현재 경로에 따른 활성 메뉴 판별
  function isActive(href: string) {
    if (href === "/admin") return pathname === "/admin";
    return pathname.startsWith(href);
  }

  const sidebarContent = (
    <nav className="flex flex-col gap-1">
      {adminNavItems.map((item) => (
        <NavLink
          key={item.href}
          href={item.href}
          label={item.label}
          icon={item.icon}
          isActive={isActive(item.href)}
          onClick={() => setMobileOpen(false)}
        />
      ))}
    </nav>
  );

  return (
    <div className="container mx-auto max-w-7xl px-4 py-6">
      <div className="flex gap-6">
        {/* 데스크톱 사이드바 */}
        <aside className="hidden w-56 shrink-0 md:block">
          <h2 className="mb-4 text-lg font-bold">관리자</h2>
          <Separator className="mb-3" />
          {sidebarContent}
        </aside>

        {/* 모바일 상단 네비게이션 */}
        <div className="flex-1">
          <div className="mb-4 flex items-center gap-3 md:hidden">
            <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
              <SheetTrigger
                render={<Button variant="outline" size="icon" />}
              >
                <Menu className="size-4" />
                <span className="sr-only">메뉴 열기</span>
              </SheetTrigger>
              <SheetContent side="left">
                <SheetHeader>
                  <SheetTitle>관리자 메뉴</SheetTitle>
                </SheetHeader>
                <div className="px-4">{sidebarContent}</div>
              </SheetContent>
            </Sheet>
            <h2 className="text-lg font-bold">관리자</h2>
          </div>

          {children}
        </div>
      </div>
    </div>
  );
}
