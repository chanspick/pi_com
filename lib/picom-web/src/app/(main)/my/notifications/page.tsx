"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { Bell, Package, TrendingDown, ArrowLeft, CheckCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/hooks/use-auth";
import {
  useNotifications,
  useMarkRead,
  useMarkAllRead,
} from "@/hooks/use-notifications";
import { formatRelativeTime } from "@/lib/utils";
import type { NotificationRow } from "@/lib/supabase/queries";

// 알림 타입별 아이콘
function NotificationIcon({ type }: { type: string | null }) {
  switch (type) {
    case "order":
      return <Package className="h-5 w-5 text-blue-500" />;
    case "price":
      return <TrendingDown className="h-5 w-5 text-green-500" />;
    case "system":
      return <Bell className="h-5 w-5 text-orange-500" />;
    default:
      return <Bell className="h-5 w-5 text-muted-foreground" />;
  }
}

// 알림 클릭 시 이동할 경로
function getNotificationHref(notification: NotificationRow): string | null {
  if (notification.related_order_id) {
    return `/my/orders/${notification.related_order_id}`;
  }
  if (notification.related_listing_id) {
    return `/listings/${notification.related_listing_id}`;
  }
  if (notification.related_sell_request_id) {
    return "/my/sell-requests";
  }
  return null;
}

export default function NotificationsPage() {
  const { user, loading: authLoading } = useAuth();
  const { notifications, isLoading } = useNotifications(user?.id);
  const markReadMutation = useMarkRead();
  const markAllReadMutation = useMarkAllRead();
  const router = useRouter();

  const handleNotificationClick = (notification: NotificationRow) => {
    // 읽지 않은 알림이면 읽음 처리
    if (!notification.is_read && user?.id) {
      markReadMutation.mutate({
        notificationId: notification.id,
        userId: user.id,
      });
    }

    // 관련 페이지로 이동
    const href = getNotificationHref(notification);
    if (href) {
      router.push(href);
    }
  };

  const handleMarkAllRead = () => {
    if (!user?.id) return;
    markAllReadMutation.mutate({ userId: user.id });
  };

  const hasUnread = notifications.some((n) => !n.is_read);

  // 로딩 상태
  if (authLoading || isLoading) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Skeleton className="h-9 w-9 rounded-lg" />
          <Skeleton className="h-7 w-20" />
        </div>
        <div className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="flex items-start gap-3 rounded-xl border bg-card p-4">
              <Skeleton className="h-10 w-10 rounded-full" />
              <div className="flex-1 space-y-2">
                <Skeleton className="h-4 w-3/4" />
                <Skeleton className="h-3 w-full" />
                <Skeleton className="h-3 w-16" />
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  // 로그인 필요
  if (!user) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-8">
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <Bell className="h-12 w-12 text-muted-foreground" />
          <p className="text-muted-foreground">
            로그인이 필요한 서비스입니다.
          </p>
          <Link href="/login">
            <Button>로그인</Button>
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      {/* 헤더 */}
      <div className="mb-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/my">
            <Button variant="ghost" size="icon">
              <ArrowLeft className="h-5 w-5" />
            </Button>
          </Link>
          <h1 className="text-xl font-bold">알림</h1>
        </div>
        {hasUnread && (
          <Button
            variant="ghost"
            size="sm"
            onClick={handleMarkAllRead}
            disabled={markAllReadMutation.isPending}
            className="text-sm text-muted-foreground"
          >
            <CheckCheck className="mr-1.5 h-4 w-4" />
            전체 읽음
          </Button>
        )}
      </div>

      {/* 빈 상태 */}
      {notifications.length === 0 ? (
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <Bell className="h-12 w-12 text-muted-foreground" />
          <p className="text-muted-foreground">알림이 없습니다</p>
        </div>
      ) : (
        /* 알림 목록 */
        <div className="space-y-2">
          {notifications.map((notification) => {
            const href = getNotificationHref(notification);
            const isClickable = !!href;

            return (
              <button
                key={notification.id}
                type="button"
                onClick={() => handleNotificationClick(notification)}
                disabled={!isClickable && notification.is_read}
                className={`w-full text-left flex items-start gap-3 rounded-xl border p-4 transition-all ${
                  !notification.is_read
                    ? "bg-primary/5 border-primary/20"
                    : "bg-card"
                } ${isClickable ? "hover:border-primary/30 hover:shadow-sm cursor-pointer" : ""}`}
              >
                {/* 아이콘 */}
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-muted">
                  <NotificationIcon type={notification.type} />
                </div>

                {/* 내용 */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start gap-2">
                    <h3
                      className={`text-sm leading-snug ${
                        !notification.is_read ? "font-semibold" : "font-medium"
                      }`}
                    >
                      {notification.title}
                    </h3>
                    {/* 읽지 않은 알림 표시 (파란 점) */}
                    {!notification.is_read && (
                      <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-blue-500" />
                    )}
                  </div>
                  {notification.body && (
                    <p className="mt-0.5 text-sm text-muted-foreground line-clamp-2">
                      {notification.body}
                    </p>
                  )}
                  <p className="mt-1 text-xs text-muted-foreground">
                    {formatRelativeTime(notification.created_at)}
                  </p>
                </div>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
