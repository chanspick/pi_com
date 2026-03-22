"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { loadTossPayments, type TossPaymentsWidgets } from "@tosspayments/tosspayments-sdk";
import {
  ArrowLeft,
  CreditCard,
  MapPin,
  Package,
  ImageIcon,
  CheckCircle2,
  Loader2,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/hooks/use-auth";
import { useAddresses } from "@/hooks/use-addresses";
import { createClient } from "@/lib/supabase/client";
import {
  fetchListingById,
  createOrder,
  createTossPayment,
  type AddressRow,
} from "@/lib/supabase/queries";
import { formatPrice, getCategoryLabel } from "@/lib/utils";

const SHIPPING_FEE = 3000;
const TOSS_CLIENT_KEY = process.env.NEXT_PUBLIC_TOSS_CLIENT_KEY!;

export default function CheckoutPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();
  const { data: addresses, isLoading: addressesLoading } = useAddresses(user?.id);
  const supabase = createClient();

  const listingId = searchParams.get("listing_id");

  const [listing, setListing] = useState<Record<string, unknown> | null>(null);
  const [listingLoading, setListingLoading] = useState(true);
  const [selectedAddressId, setSelectedAddressId] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 토스 위젯
  const [widgets, setWidgets] = useState<TossPaymentsWidgets | null>(null);
  const [widgetReady, setWidgetReady] = useState(false);
  const paymentMethodRef = useRef<HTMLDivElement>(null);
  const agreementRef = useRef<HTMLDivElement>(null);

  // 매물 정보 가져오기
  useEffect(() => {
    async function loadListing() {
      if (!listingId) { setListingLoading(false); return; }
      setListingLoading(true);
      const result = await fetchListingById(supabase, listingId);
      if (result.listing) {
        setListing(result.listing as unknown as Record<string, unknown>);
      }
      setListingLoading(false);
    }
    loadListing();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [listingId]);

  // 기본 배송지 자동 선택
  useEffect(() => {
    if (addresses && addresses.length > 0 && !selectedAddressId) {
      const defaultAddr = addresses.find((a) => a.is_default);
      setSelectedAddressId(defaultAddr?.id ?? addresses[0].id);
    }
  }, [addresses, selectedAddressId]);

  // 토스 위젯 초기화
  const initWidgets = useCallback(async () => {
    if (!user || !listing) return;
    try {
      const tossPayments = await loadTossPayments(TOSS_CLIENT_KEY);
      const w = tossPayments.widgets({ customerKey: user.id });
      const amount = (listing.price as number) + SHIPPING_FEE;
      await w.setAmount({ currency: "KRW", value: amount });
      setWidgets(w);
    } catch (err) {
      console.error("토스 위젯 초기화 실패:", err);
    }
  }, [user, listing]);

  useEffect(() => {
    initWidgets();
  }, [initWidgets]);

  // 위젯 렌더링
  useEffect(() => {
    if (!widgets) return;
    let mounted = true;

    async function render() {
      try {
        if (paymentMethodRef.current) {
          await widgets!.renderPaymentMethods({
            selector: "#payment-method",
            variantKey: "DEFAULT",
          });
        }
        if (agreementRef.current) {
          await widgets!.renderAgreement({
            selector: "#agreement",
            variantKey: "AGREEMENT",
          });
        }
        if (mounted) setWidgetReady(true);
      } catch (err) {
        console.error("위젯 렌더링 실패:", err);
      }
    }

    render();
    return () => { mounted = false; };
  }, [widgets]);

  // 가격
  const itemPrice = (listing?.price as number) ?? 0;
  const totalAmount = itemPrice + SHIPPING_FEE;
  const selectedAddress = addresses?.find((a) => a.id === selectedAddressId) ?? null;

  // 결제 처리
  const handleCheckout = async () => {
    if (!user || !listing || !selectedAddress || !widgets) return;

    setIsProcessing(true);
    setError(null);

    try {
      const sellerId = listing.seller_id as string;
      const basePartsObj = listing.base_parts as Record<string, unknown> | null;
      const listingTitle = (listing.title as string) ??
        (basePartsObj?.name as string) ??
        "상품";

      // 1. 주문 생성
      const { order, error: orderError } = await createOrder(supabase, {
        buyer_id: user.id,
        seller_id: sellerId,
        listing_id: listingId!,
        total_amount: totalAmount,
        shipping_fee: SHIPPING_FEE,
        shipping_address: {
          recipient_name: selectedAddress.recipient_name,
          phone: selectedAddress.phone,
          postal_code: selectedAddress.postal_code,
          address_line1: selectedAddress.address_line1,
          address_line2: selectedAddress.address_line2,
        },
      });

      if (orderError || !order) {
        throw new Error(orderError?.message ?? "주문 생성에 실패했습니다.");
      }

      // 2. 결제 레코드 생성
      const { error: paymentError } = await createTossPayment(supabase, {
        order_id: order.id,
        amount: totalAmount,
        order_name: listingTitle,
      });

      if (paymentError) {
        throw new Error(paymentError.message ?? "결제 정보 생성에 실패했습니다.");
      }

      // 3. 토스페이먼츠 결제 요청
      await widgets.requestPayment({
        orderId: order.id,
        orderName: listingTitle,
        successUrl: `${window.location.origin}/checkout/success`,
        failUrl: `${window.location.origin}/checkout/fail`,
        customerEmail: user.email ?? undefined,
        customerName: selectedAddress.recipient_name,
      });
    } catch (err) {
      // 사용자가 결제를 취소한 경우
      if (err instanceof Error && err.message.includes("USER_CANCEL")) {
        setError(null);
      } else {
        setError(
          err instanceof Error ? err.message : "결제 처리 중 오류가 발생했습니다."
        );
      }
      setIsProcessing(false);
    }
  };

  // 로딩 상태
  if (authLoading || listingLoading) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Skeleton className="h-9 w-9 rounded-lg" />
          <Skeleton className="h-7 w-24" />
        </div>
        <div className="space-y-4">
          <Skeleton className="h-40 rounded-xl" />
          <Skeleton className="h-32 rounded-xl" />
          <Skeleton className="h-24 rounded-xl" />
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <CreditCard className="h-12 w-12 text-muted-foreground" />
          <p className="text-muted-foreground">로그인이 필요한 서비스입니다.</p>
          <Link href="/login">
            <Button>로그인</Button>
          </Link>
        </div>
      </div>
    );
  }

  if (!listing) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <Package className="h-12 w-12 text-muted-foreground" />
          <p className="text-muted-foreground">결제할 상품 정보를 찾을 수 없습니다.</p>
          <Link href="/listings">
            <Button>매물 둘러보기</Button>
          </Link>
        </div>
      </div>
    );
  }

  const baseParts = listing.base_parts as Record<string, unknown> | null;
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

  return (
    <div className="mx-auto max-w-3xl px-4 py-8">
      {/* 헤더 */}
      <div className="mb-6 flex items-center gap-3">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => router.back()}
          aria-label="뒤로 가기"
        >
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <h1 className="text-xl font-bold">주문/결제</h1>
      </div>

      <div className="space-y-4">
        {/* 주문 상품 */}
        <Card>
          <CardContent>
            <h2 className="text-[15px] font-semibold mb-3 flex items-center gap-2">
              <Package className="h-4 w-4" />
              주문 상품
            </h2>
            <div className="flex gap-4">
              <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-lg bg-muted">
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
              </div>
              <div className="flex flex-1 flex-col justify-center gap-1 min-w-0">
                {category && (
                  <Badge variant="secondary" className="w-fit text-[10px] font-semibold">
                    {getCategoryLabel(category)}
                  </Badge>
                )}
                <p className="text-[14px] font-semibold leading-snug truncate">{title}</p>
                <span className="text-[16px] font-bold text-foreground">
                  {formatPrice(itemPrice)}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* 배송지 선택 */}
        <Card>
          <CardContent>
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-[15px] font-semibold flex items-center gap-2">
                <MapPin className="h-4 w-4" />
                배송지
              </h2>
              <Link href="/my/addresses" className="text-[13px] text-primary hover:underline">
                배송지 관리
              </Link>
            </div>

            {addressesLoading ? (
              <div className="space-y-2">
                <Skeleton className="h-4 w-32" />
                <Skeleton className="h-4 w-48" />
              </div>
            ) : !addresses || addresses.length === 0 ? (
              <div className="flex flex-col items-center gap-3 py-6">
                <p className="text-[13px] text-muted-foreground">등록된 배송지가 없습니다.</p>
                <Link href="/my/addresses">
                  <Button size="sm" variant="outline">배송지 추가하기</Button>
                </Link>
              </div>
            ) : (
              <div className="space-y-2">
                {addresses.map((address: AddressRow) => (
                  <label
                    key={address.id}
                    className={`flex items-start gap-3 rounded-lg border p-3 cursor-pointer transition-all ${
                      selectedAddressId === address.id
                        ? "border-primary bg-primary/5"
                        : "border-border hover:border-primary/30"
                    }`}
                  >
                    <input
                      type="radio"
                      name="address"
                      value={address.id}
                      checked={selectedAddressId === address.id}
                      onChange={() => setSelectedAddressId(address.id)}
                      className="mt-1 h-4 w-4 accent-primary"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <span className="text-[14px] font-semibold">
                          {address.recipient_name}
                        </span>
                        {address.is_default && (
                          <Badge variant="default" className="text-[10px]">기본</Badge>
                        )}
                      </div>
                      <p className="text-[13px] text-muted-foreground">{address.phone}</p>
                      <p className="text-[13px] text-foreground">
                        ({address.postal_code}) {address.address_line1}
                        {address.address_line2 && ` ${address.address_line2}`}
                      </p>
                    </div>
                  </label>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* 토스 결제 수단 위젯 */}
        <Card>
          <CardContent>
            <h2 className="text-[15px] font-semibold mb-3 flex items-center gap-2">
              <CreditCard className="h-4 w-4" />
              결제 수단
            </h2>
            {!widgetReady && (
              <div className="flex items-center gap-2 py-4 text-[13px] text-muted-foreground">
                <Loader2 className="h-4 w-4 animate-spin" />
                결제 수단을 불러오는 중...
              </div>
            )}
            <div id="payment-method" ref={paymentMethodRef} />
          </CardContent>
        </Card>

        {/* 토스 약관 동의 위젯 */}
        <div id="agreement" ref={agreementRef} />

        {/* 결제 요약 */}
        <Card>
          <CardContent>
            <h2 className="text-[15px] font-semibold mb-3">결제 금액</h2>
            <div className="space-y-2 text-[14px]">
              <div className="flex justify-between">
                <span className="text-muted-foreground">상품 금액</span>
                <span>{formatPrice(itemPrice)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">배송비</span>
                <span>{formatPrice(SHIPPING_FEE)}</span>
              </div>
              <Separator />
              <div className="flex justify-between text-[16px] font-bold pt-1">
                <span>총 결제 금액</span>
                <span className="text-primary">{formatPrice(totalAmount)}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* 에러 */}
        {error && (
          <div className="rounded-lg border border-destructive/50 bg-destructive/10 p-3 text-[13px] text-destructive">
            {error}
          </div>
        )}

        {/* 결제 버튼 */}
        <Button
          className="w-full h-12 text-base font-semibold"
          size="lg"
          onClick={handleCheckout}
          disabled={isProcessing || !selectedAddressId || !listing || !widgetReady}
        >
          {isProcessing ? (
            <>
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              결제 처리 중...
            </>
          ) : (
            <>
              <CheckCircle2 className="h-4 w-4 mr-2" />
              {formatPrice(totalAmount)} 결제하기
            </>
          )}
        </Button>

        <p className="text-[12px] text-muted-foreground text-center">
          주문 내용을 확인하였으며, 결제에 동의합니다.
        </p>
      </div>
    </div>
  );
}
