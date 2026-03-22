"use client";

import Link from "next/link";
import Image from "next/image";
import {
  ArrowLeft,
  Trash2,
  ShoppingCart,
  ImageIcon,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/hooks/use-auth";
import { useCart, useRemoveFromCart } from "@/hooks/use-cart";
import {
  formatPrice,
  getCategoryLabel,
} from "@/lib/utils";

export default function CartPage() {
  const { user, loading: authLoading } = useAuth();
  const { items, isLoading, totalPrice } = useCart(user?.id);
  const removeFromCartMutation = useRemoveFromCart();

  const handleRemove = (cartItemId: string) => {
    if (!user?.id) return;
    removeFromCartMutation.mutate({ cartItemId, userId: user.id });
  };

  // 로딩 상태
  if (authLoading || isLoading) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Skeleton className="h-9 w-9 rounded-lg" />
          <Skeleton className="h-7 w-28" />
        </div>
        <div className="space-y-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <div
              key={i}
              className="flex gap-4 rounded-xl border bg-card p-4"
            >
              <Skeleton className="h-20 w-20 shrink-0 rounded-lg" />
              <div className="flex-1 space-y-2">
                <Skeleton className="h-3 w-16" />
                <Skeleton className="h-4 w-48" />
                <Skeleton className="h-5 w-24" />
              </div>
              <Skeleton className="h-8 w-8 rounded-lg" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  // 로그인 필요
  if (!user) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <ShoppingCart className="h-12 w-12 text-muted-foreground" />
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
    <div className="mx-auto max-w-3xl px-4 py-8">
      {/* 헤더 */}
      <div className="mb-6 flex items-center gap-3">
        <Link href="/my">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <h1 className="text-xl font-bold">장바구니</h1>
        {items.length > 0 && (
          <span className="text-sm text-muted-foreground">
            {items.length}개
          </span>
        )}
      </div>

      {/* 빈 상태 */}
      {items.length === 0 ? (
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <ShoppingCart className="h-12 w-12 text-muted-foreground" />
          <p className="text-muted-foreground">장바구니가 비어있습니다</p>
          <Link href="/listings">
            <Button>매물 둘러보기</Button>
          </Link>
        </div>
      ) : (
        <>
          {/* 장바구니 아이템 목록 */}
          <div className="space-y-3">
            {items.map((item: Record<string, unknown>) => {
              const listing = item.listings as Record<
                string,
                unknown
              > | null;
              if (!listing) return null;

              const baseParts = listing.base_parts as Record<
                string,
                unknown
              > | null;
              const imageUrl = (listing.images as string[] | null)?.[0];
              const title =
                (listing.title as string) ||
                [baseParts?.name, baseParts?.brand, baseParts?.model]
                  .filter(Boolean)
                  .join(" ") ||
                "제목 없음";
              const category =
                (listing.category as string) ||
                (baseParts?.category as string) ||
                "";
              const price = (listing.price as number) ?? 0;
              const listingId = listing.id as string;
              const cartItemId = item.id as string;

              return (
                <div
                  key={cartItemId}
                  className="flex gap-4 rounded-xl border bg-card p-4 transition-all hover:border-primary/30"
                >
                  {/* 이미지 (썸네일) */}
                  <Link
                    href={`/listings/${listingId}`}
                    className="relative h-20 w-20 shrink-0 overflow-hidden rounded-lg bg-muted"
                  >
                    {imageUrl ? (
                      <Image
                        src={imageUrl}
                        alt={title}
                        fill
                        className="object-cover"
                        sizes="80px"
                      />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center text-muted-foreground">
                        <ImageIcon className="h-5 w-5" />
                      </div>
                    )}
                  </Link>

                  {/* 정보 */}
                  <div className="flex flex-1 flex-col justify-center gap-1 min-w-0">
                    {category && (
                      <Badge
                        variant="secondary"
                        className="w-fit text-[10px] font-semibold"
                      >
                        {getCategoryLabel(category)}
                      </Badge>
                    )}
                    <Link
                      href={`/listings/${listingId}`}
                      className="text-[14px] font-semibold leading-snug truncate hover:text-primary transition-colors"
                    >
                      {title}
                    </Link>
                    <span className="text-[16px] font-bold text-foreground">
                      {formatPrice(price)}
                    </span>
                  </div>

                  {/* 삭제 버튼 */}
                  <div className="flex items-center">
                    <Button
                      variant="ghost"
                      size="icon-sm"
                      onClick={() => handleRemove(cartItemId)}
                      aria-label="장바구니에서 삭제"
                    >
                      <Trash2 className="h-4 w-4 text-muted-foreground" />
                    </Button>
                  </div>
                </div>
              );
            })}
          </div>

          {/* 요약 및 결제 */}
          <div className="mt-6">
            <Separator />
            <div className="py-4 space-y-3">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">
                  총 {items.length}개 상품
                </span>
                <span className="text-lg font-bold">
                  {formatPrice(totalPrice)}
                </span>
              </div>
              {items.length === 1 ? (
                <Link href={`/checkout?listing_id=${(items[0] as Record<string, unknown>).listing_id ?? ""}`}>
                  <Button
                    className="w-full h-12 text-base font-semibold"
                    size="lg"
                  >
                    결제하기
                  </Button>
                </Link>
              ) : items.length > 1 ? (
                <div className="space-y-2">
                  <p className="text-[12px] text-muted-foreground text-center">
                    중고 부품 특성상 상품별 개별 결제가 필요합니다.
                  </p>
                  {items.map((item) => {
                    const cartItem = item as Record<string, unknown>;
                    const li = cartItem.listings as Record<string, unknown> | null;
                    return (
                      <Link
                        key={cartItem.id as string}
                        href={`/checkout?listing_id=${cartItem.listing_id ?? ""}`}
                      >
                        <Button
                          variant="outline"
                          className="w-full h-10 text-sm font-semibold mb-1"
                        >
                          {(li?.title as string) ?? "상품"} 결제하기
                        </Button>
                      </Link>
                    );
                  })}
                </div>
              ) : null}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
