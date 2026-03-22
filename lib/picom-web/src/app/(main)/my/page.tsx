"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/hooks/use-auth";
import { useProfile } from "@/hooks/use-profile";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
} from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Heart,
  ShoppingCart,
  Package,
  Store,
  Send,
  Upload,
  MapPin,
  Bell,
  Settings,
  Pencil,
  LogOut,
  ChevronRight,
  Wallet,
} from "lucide-react";

const menuItems = [
  {
    title: "즐겨찾기",
    description: "관심 있는 매물을 모아보세요",
    href: "/my/favorites",
    icon: Heart,
  },
  {
    title: "장바구니",
    description: "구매할 매물을 담아두세요",
    href: "/my/cart",
    icon: ShoppingCart,
  },
  {
    title: "주문내역",
    description: "구매한 주문을 확인하세요",
    href: "/my/orders",
    icon: Package,
  },
  {
    title: "판매내역",
    description: "내가 판매한 매물을 관리하세요",
    href: "/my/sales",
    icon: Store,
  },
  {
    title: "판매신청",
    description: "검수 후 위탁 판매를 신청하세요",
    href: "/my/sell-requests",
    icon: Send,
  },
  {
    title: "직접 판매",
    description: "직접 매물을 등록하고 판매하세요",
    href: "/sell/direct",
    icon: Upload,
  },
  {
    title: "정산 내역",
    description: "판매 정산 내역을 확인하세요",
    href: "/my/settlements",
    icon: Wallet,
  },
  {
    title: "배송지 관리",
    description: "배송 주소를 관리하세요",
    href: "/my/addresses",
    icon: MapPin,
  },
  {
    title: "알림",
    description: "가격 알림과 소식을 확인하세요",
    href: "/my/notifications",
    icon: Bell,
  },
  {
    title: "설정",
    description: "계정과 앱 설정을 변경하세요",
    href: "/my/settings",
    icon: Settings,
  },
];

// 소셜 프로바이더 라벨/색상 매핑
function getProviderBadge(provider: string) {
  switch (provider) {
    case "google":
      return { label: "Google", variant: "outline" as const };
    case "kakao":
      return { label: "Kakao", variant: "secondary" as const };
    case "email":
      return { label: "Email", variant: "outline" as const };
    default:
      return { label: provider, variant: "outline" as const };
  }
}

function ProfileCardSkeleton() {
  return (
    <Card>
      <CardContent className="flex items-center gap-5 pt-2">
        <Skeleton className="h-20 w-20 rounded-full" />
        <div className="flex-1 space-y-2">
          <Skeleton className="h-6 w-32" />
          <Skeleton className="h-4 w-48" />
          <Skeleton className="h-5 w-16" />
        </div>
      </CardContent>
    </Card>
  );
}

function MenuGridSkeleton() {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
      {Array.from({ length: 8 }).map((_, i) => (
        <Card key={i}>
          <CardContent className="flex flex-col items-center gap-3 py-6">
            <Skeleton className="h-10 w-10 rounded-xl" />
            <Skeleton className="h-4 w-16" />
            <Skeleton className="h-3 w-24" />
          </CardContent>
        </Card>
      ))}
    </div>
  );
}

export default function MyPage() {
  const router = useRouter();
  const { user, loading: authLoading, signOut } = useAuth();
  const { profile, isLoading: profileLoading } = useProfile(user?.id);

  // 비로그인 사용자 리다이렉트
  useEffect(() => {
    if (!authLoading && !user) {
      router.replace("/login");
    }
  }, [authLoading, user, router]);

  // 로그인 확인 중이거나 비로그인 상태
  if (authLoading || !user) {
    return (
      <div className="container mx-auto max-w-3xl px-4 py-8 space-y-6">
        <ProfileCardSkeleton />
        <MenuGridSkeleton />
      </div>
    );
  }

  const isLoading = profileLoading;
  const displayName =
    profile?.display_name ||
    user.user_metadata?.full_name ||
    user.email?.split("@")[0] ||
    "사용자";
  const avatarUrl = profile?.avatar_url || user.user_metadata?.avatar_url;
  const email = profile?.email || user.email || "";
  const providers = profile?.providers ?? [];

  return (
    <div className="container mx-auto max-w-3xl px-4 py-8 space-y-6">
      {/* 프로필 카드 */}
      {isLoading ? (
        <ProfileCardSkeleton />
      ) : (
        <Card>
          <CardContent className="flex items-center gap-5 pt-2">
            {/* 아바타 */}
            <Avatar className="h-20 w-20 text-2xl">
              <AvatarImage src={avatarUrl ?? undefined} alt={displayName} />
              <AvatarFallback className="bg-primary/10 text-primary text-xl font-bold">
                {displayName[0]?.toUpperCase() || "U"}
              </AvatarFallback>
            </Avatar>

            {/* 정보 */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <h2 className="text-lg font-bold truncate">{displayName}</h2>
                <Link href="/my/profile/edit">
                  <Button variant="ghost" size="icon-xs" aria-label="프로필 수정">
                    <Pencil className="h-3.5 w-3.5" />
                  </Button>
                </Link>
              </div>
              <p className="text-sm text-muted-foreground truncate">{email}</p>
              {providers.length > 0 && (
                <div className="flex gap-1.5 mt-2 flex-wrap">
                  {providers.map((p) => {
                    const badge = getProviderBadge(p);
                    return (
                      <Badge key={p} variant={badge.variant} className="text-[11px]">
                        {badge.label}
                      </Badge>
                    );
                  })}
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      <Separator />

      {/* 메뉴 그리드 */}
      {isLoading ? (
        <MenuGridSkeleton />
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {menuItems.map((item) => (
            <Link key={item.href} href={item.href} className="block group">
              <Card className="h-full hover:border-primary/30 hover:shadow-md transition-all cursor-pointer">
                <CardContent className="flex flex-col items-center gap-2.5 py-5 px-3 text-center">
                  <div className="w-10 h-10 rounded-xl bg-primary/5 group-hover:bg-primary/10 flex items-center justify-center transition-colors">
                    <item.icon className="h-5 w-5 text-primary/70 group-hover:text-primary transition-colors" />
                  </div>
                  <div>
                    <p className="font-semibold text-[13px]">{item.title}</p>
                    <p className="text-[11px] text-muted-foreground mt-0.5 leading-snug">
                      {item.description}
                    </p>
                  </div>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}

      {/* 로그아웃 */}
      <div className="pt-2">
        <Button
          variant="ghost"
          className="w-full justify-start text-muted-foreground hover:text-destructive"
          onClick={signOut}
        >
          <LogOut className="h-4 w-4 mr-2" />
          로그아웃
        </Button>
      </div>
    </div>
  );
}
