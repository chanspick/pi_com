import { SupabaseClient } from "@supabase/supabase-js";
import { Database, Json } from "@/types/database.types";

export type ListingRow = Database["public"]["Tables"]["listings"]["Row"];
export type BasePartRow = Database["public"]["Tables"]["base_parts"]["Row"];

export type ListingWithBasePart = ListingRow & {
  base_parts: Pick<BasePartRow, "name" | "brand" | "model" | "category"> | null;
};


export type ListingWithFullBasePart = ListingRow & {
  base_parts: BasePartRow | null;
};

export interface ListingsQueryParams {
  category?: string;
  sort?: string;
  minPrice?: number;
  maxPrice?: number;
  status?: string;
  cursor?: string;
  limit?: number;
}

export async function fetchListings(
  supabase: SupabaseClient<Database>,
  params: ListingsQueryParams = {}
) {
  const {
    category,
    sort = "newest",
    minPrice,
    maxPrice,
    status = "active",
    cursor,
    limit = 20,
  } = params;

  let query = supabase
    .from("listings")
    .select(
      "*, base_parts (name, brand, model, category)",
      { count: "exact" }
    )
    .eq("status", status)
    .limit(limit);

  if (category) {
    query = query.eq("category", category);
  }

  if (minPrice !== undefined) {
    query = query.gte("price", minPrice);
  }

  if (maxPrice !== undefined) {
    query = query.lte("price", maxPrice);
  }

  // 정렬
  switch (sort) {
    case "price_asc":
      query = query.order("price", { ascending: true });
      break;
    case "price_desc":
      query = query.order("price", { ascending: false });
      break;
    case "popular":
      query = query.order("view_count", { ascending: false });
      break;
    case "newest":
    default:
      query = query.order("created_at", { ascending: false });
      break;
  }

  // 커서 기반 페이지네이션
  if (cursor) {
    query = query.lt("created_at", cursor);
  }

  const { data, error, count } = await query;

  return {
    listings: (data as ListingWithBasePart[] | null) ?? [],
    error,
    count: count ?? 0,
  };
}

export async function fetchListingById(
  supabase: SupabaseClient<Database>,
  listingId: string
) {
  const { data, error } = await supabase
    .from("listings")
    .select("*, base_parts (*)")
    .eq("id", listingId)
    .single();

  return { listing: data as ListingWithFullBasePart | null, error };
}

// M5: Base parts by category
export type PriceHistoryRow = Database["public"]["Tables"]["price_history"]["Row"];

export async function fetchBasePartsByCategory(
  supabase: SupabaseClient<Database>,
  category: string,
  search?: string
) {
  let query = supabase
    .from("base_parts")
    .select("*", { count: "exact" })
    .eq("category", category)
    .gt("listing_count", 0)
    .order("listing_count", { ascending: false });

  if (search) {
    query = query.or("name.ilike.%"+search+"%,brand.ilike.%"+search+"%,model.ilike.%"+search+"%");
  }

  const { data, error, count } = await query;
  return { parts: (data as BasePartRow[] | null) ?? [], error, count: count ?? 0 };
}

// M6: Price history
export async function fetchPriceHistory(
  supabase: SupabaseClient<Database>,
  basePartId: string,
  days: number = 30
) {
  const since = new Date();
  since.setDate(since.getDate() - days);

  const { data, error } = await supabase
    .from("price_history")
    .select("*")
    .eq("base_part_id", basePartId)
    .gte("recorded_at", since.toISOString())
    .order("recorded_at", { ascending: true });

  return { history: (data as PriceHistoryRow[] | null) ?? [], error };
}

// M7: Search (unified)
export async function searchAll(
  supabase: SupabaseClient<Database>,
  query: string,
  limit: number = 20
) {
  const searchPattern = "%" + query + "%";

  const [partsResult, listingsResult] = await Promise.all([
    supabase
      .from("base_parts")
      .select("*")
      .or("name.ilike."+searchPattern+",brand.ilike."+searchPattern+",model.ilike."+searchPattern)
      .gt("listing_count", 0)
      .order("listing_count", { ascending: false })
      .limit(limit),
    supabase
      .from("listings")
      .select("*, base_parts (name, brand, model, category)")
      .eq("status", "active")
      .or("title.ilike."+searchPattern)
      .order("created_at", { ascending: false })
      .limit(limit),
  ]);

  return {
    parts: (partsResult.data as BasePartRow[] | null) ?? [],
    listings: (listingsResult.data as ListingWithBasePart[] | null) ?? [],
    partsError: partsResult.error,
    listingsError: listingsResult.error,
  };
}

// P1: BasePart의 active 매물 목록 (basePartId 필터)
export async function fetchListingsByBasePart(
  supabase: SupabaseClient<Database>,
  basePartId: string,
  params: { sort?: string; cursor?: string; limit?: number } = {}
) {
  const { sort = "newest", cursor, limit = 20 } = params;

  let query = supabase
    .from("listings")
    .select("*, base_parts (name, brand, model, category)", { count: "exact" })
    .eq("base_part_id", basePartId)
    .eq("status", "active")
    .limit(limit);

  switch (sort) {
    case "price_asc":
      query = query.order("price", { ascending: true });
      break;
    case "price_desc":
      query = query.order("price", { ascending: false });
      break;
    case "newest":
    default:
      query = query.order("created_at", { ascending: false });
      break;
  }

  if (cursor) {
    query = query.lt("created_at", cursor);
  }

  const { data, error, count } = await query;
  return {
    listings: (data as ListingWithBasePart[] | null) ?? [],
    error,
    count: count ?? 0,
  };
}
// P0: 확장된 PriceHistory (90일, lowest_price + average_price 포함)
export async function fetchPriceHistoryExtended(
  supabase: SupabaseClient<Database>,
  basePartId: string,
  days: number = 90
) {
  const since = new Date();
  since.setDate(since.getDate() - days);

  const { data, error } = await supabase
    .from("price_history")
    .select("*")
    .eq("base_part_id", basePartId)
    .gte("recorded_at", since.toISOString())
    .order("recorded_at", { ascending: true });

  return { history: (data as PriceHistoryRow[] | null) ?? [], error };
}

// P2: 즐겨찾기
export type FavoriteRow = Database["public"]["Tables"]["favorites"]["Row"];

export async function fetchFavorites(
  supabase: SupabaseClient<Database>,
  userId: string
) {
  const { data, error } = await supabase
    .from("favorites")
    .select("*, listings (*, base_parts (name, brand, model, category))")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  return { favorites: data ?? [], error };
}

export async function toggleFavorite(
  supabase: SupabaseClient<Database>,
  userId: string,
  listingId: string
) {
  const { data: existing } = await supabase
    .from("favorites")
    .select("id")
    .eq("user_id", userId)
    .eq("listing_id", listingId)
    .single();

  if (existing) {
    const { error } = await supabase.from("favorites").delete().eq("id", (existing as any).id);
    return { isFavorited: false, error };
  } else {
    const { error } = await supabase.from("favorites").insert({ user_id: userId, listing_id: listingId } as any);
    return { isFavorited: true, error };
  }
}
// P4: 장바구니
export type CartItemRow = Database["public"]["Tables"]["cart_items"]["Row"];

export async function fetchCartItems(
  supabase: SupabaseClient<Database>,
  userId: string
) {
  const { data, error } = await supabase
    .from("cart_items")
    .select("*, listings (*, base_parts (name, brand, model, category))")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  return { items: data ?? [], error };
}

export async function addToCart(
  supabase: SupabaseClient<Database>,
  userId: string,
  listingId: string
) {
  const { data, error } = await supabase
    .from("cart_items")
    .insert({ user_id: userId, listing_id: listingId } as any)
    .select()
    .single();
  return { item: data, error };
}

export async function removeFromCart(
  supabase: SupabaseClient<Database>,
  cartItemId: string
) {
  const { error } = await supabase.from("cart_items").delete().eq("id", cartItemId);
  return { error };
}

// P3: 프로필
export type ProfileRow = Database["public"]["Tables"]["profiles"]["Row"];

export async function fetchProfile(
  supabase: SupabaseClient<Database>,
  userId: string
) {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single();
  return { profile: data as ProfileRow | null, error };
}

export async function updateProfile(
  supabase: SupabaseClient<Database>,
  userId: string,
  updates: { display_name?: string; avatar_url?: string }
) {
  const { data, error } = await supabase
    .from("profiles")
    .update(updates)
    .eq("id", userId)
    .select()
    .single();
  return { profile: data as ProfileRow | null, error };
}

// P3: 배송지
export type AddressRow = Database["public"]["Tables"]["addresses"]["Row"];

export async function fetchAddresses(
  supabase: SupabaseClient<Database>,
  userId: string
) {
  const { data, error } = await supabase
    .from("addresses")
    .select("*")
    .eq("user_id", userId)
    .order("is_default", { ascending: false })
    .order("created_at", { ascending: false });
  return { addresses: (data as AddressRow[] | null) ?? [], error };
}

export async function createAddress(
  supabase: SupabaseClient<Database>,
  address: {
    user_id: string;
    recipient_name: string;
    phone: string;
    postal_code: string;
    address_line1: string;
    address_line2?: string;
    is_default?: boolean;
  }
) {
  // 기본 배송지로 설정하는 경우, 기존 기본 배송지 해제
  if (address.is_default) {
    await supabase
      .from("addresses")
      .update({ is_default: false })
      .eq("user_id", address.user_id);
  }
  const { data, error } = await supabase
    .from("addresses")
    .insert(address)
    .select()
    .single();
  return { address: data as AddressRow | null, error };
}

export async function updateAddress(
  supabase: SupabaseClient<Database>,
  addressId: string,
  userId: string,
  updates: Partial<{
    recipient_name: string;
    phone: string;
    postal_code: string;
    address_line1: string;
    address_line2: string;
    is_default: boolean;
  }>
) {
  if (updates.is_default) {
    await supabase
      .from("addresses")
      .update({ is_default: false })
      .eq("user_id", userId);
  }
  const { data, error } = await supabase
    .from("addresses")
    .update(updates)
    .eq("id", addressId)
    .select()
    .single();
  return { address: data as AddressRow | null, error };
}

export async function deleteAddress(
  supabase: SupabaseClient<Database>,
  addressId: string
) {
  const { error } = await supabase
    .from("addresses")
    .delete()
    .eq("id", addressId);
  return { error };
}

// P4: 판매 신청
export type SellRequestRow = Database["public"]["Tables"]["sell_requests"]["Row"];

export async function fetchSellRequests(
  supabase: SupabaseClient<Database>,
  userId: string,
  status?: string
) {
  let query = supabase
    .from("sell_requests")
    .select("*")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });
  if (status) {
    query = query.eq("status", status);
  }
  const { data, error } = await query;
  return { sellRequests: (data as SellRequestRow[] | null) ?? [], error };
}

export async function createSellRequest(
  supabase: SupabaseClient<Database>,
  request: {
    user_id: string;
    category: string;
    title: string;
    description?: string;
    desired_price?: number;
    images?: string[];
    specs?: Json;
    is_secondhand?: boolean;
    has_warranty?: boolean;
    warranty_months_left?: number;
  }
) {
  const { data, error } = await supabase
    .from("sell_requests")
    .insert(request)
    .select()
    .single();
  return { sellRequest: data as SellRequestRow | null, error };
}

export async function updateSellRequest(
  supabase: SupabaseClient<Database>,
  requestId: string,
  updates: { status?: string }
) {
  const { data, error } = await supabase
    .from("sell_requests")
    .update(updates)
    .eq("id", requestId)
    .select()
    .single();
  return { sellRequest: data as SellRequestRow | null, error };
}

// P4: 검증 결과
export type VerificationResultRow = Database["public"]["Tables"]["verification_results"]["Row"];

export async function fetchVerificationResult(
  supabase: SupabaseClient<Database>,
  listingId: string
) {
  const { data, error } = await supabase
    .from("verification_results")
    .select("*")
    .eq("listing_id", listingId)
    .single();
  return { result: data as VerificationResultRow | null, error };
}

// P4: 매물 직접 등록
export async function createListing(
  supabase: SupabaseClient<Database>,
  listing: {
    seller_id: string;
    title: string;
    price: number;
    category: string;
    description?: string;
    original_price?: number;
    condition?: string;
    condition_score?: number;
    images?: string[];
    base_part_id?: string;
    specs?: Json;
  }
) {
  const { data, error } = await supabase
    .from("listings")
    .insert({ ...listing, status: "active" } as Database["public"]["Tables"]["listings"]["Insert"])
    .select()
    .single();
  return { listing: data as ListingRow | null, error };
}

// P5: 주문 내역
export type OrderRow = Database["public"]["Tables"]["orders"]["Row"];

export type OrderWithListing = OrderRow & {
  listings: Pick<ListingRow, "title" | "price" | "images" | "category"> | null;
};

export type OrderWithListingDetail = OrderRow & {
  listings: Pick<ListingRow, "title" | "price" | "images" | "category" | "description"> | null;
};

export async function fetchOrders(
  supabase: SupabaseClient<Database>,
  userId: string,
  status?: string
) {
  let query = supabase
    .from("orders")
    .select("*, listings(title, price, images, category)")
    .eq("buyer_id", userId)
    .order("created_at", { ascending: false });
  if (status) {
    query = query.eq("status", status);
  }
  const { data, error } = await query;
  return { orders: (data as OrderWithListing[] | null) ?? [], error };
}

export async function fetchOrderById(
  supabase: SupabaseClient<Database>,
  orderId: string
) {
  const { data, error } = await supabase
    .from("orders")
    .select("*, listings(title, price, images, category, description)")
    .eq("id", orderId)
    .single();
  return { order: data as OrderWithListingDetail | null, error };
}

export async function cancelOrder(
  supabase: SupabaseClient<Database>,
  orderId: string
) {
  const { error } = await supabase
    .from("orders")
    .update({ status: "cancelled", cancelled_at: new Date().toISOString() })
    .eq("id", orderId);
  return { error };
}

// P5: 판매 내역 (내 매물)
export async function fetchMyListings(
  supabase: SupabaseClient<Database>,
  userId: string,
  status?: string
) {
  let query = supabase
    .from("listings")
    .select("*")
    .eq("seller_id", userId)
    .order("created_at", { ascending: false });
  if (status) {
    query = query.eq("status", status);
  }
  const { data, error } = await query;
  return { listings: (data as ListingRow[] | null) ?? [], error };
}

export async function deleteListing(
  supabase: SupabaseClient<Database>,
  listingId: string
) {
  const { error } = await supabase
    .from("listings")
    .update({ status: "deleted" })
    .eq("id", listingId);
  return { error };
}

export async function updateListingStatus(
  supabase: SupabaseClient<Database>,
  listingId: string,
  status: string
) {
  const { error } = await supabase
    .from("listings")
    .update({ status })
    .eq("id", listingId);
  return { error };
}

// P5: 주문 생성 / 결제
export type TossPaymentRow = Database["public"]["Tables"]["toss_payments"]["Row"];

export async function createOrder(
  supabase: SupabaseClient<Database>,
  order: {
    buyer_id: string;
    seller_id: string;
    listing_id: string;
    total_amount: number;
    shipping_fee?: number;
    shipping_address?: Json | null;
  }
) {
  const { data, error } = await supabase
    .from("orders")
    .insert(order)
    .select()
    .single();
  return { order: data as OrderRow | null, error };
}

export async function createTossPayment(
  supabase: SupabaseClient<Database>,
  payment: {
    order_id: string;
    amount: number;
    order_name?: string;
  }
) {
  const { data, error } = await supabase
    .from("toss_payments")
    .insert(payment)
    .select()
    .single();
  return { payment: data as TossPaymentRow | null, error };
}

export async function updateOrderStatus(
  supabase: SupabaseClient<Database>,
  orderId: string,
  updates: {
    status?: string;
    shipping_status?: string;
    tracking_number?: string;
  }
) {
  const { data, error } = await supabase
    .from("orders")
    .update(updates)
    .eq("id", orderId)
    .select()
    .single();
  return { order: data as OrderRow | null, error };
}

export async function updateTossPaymentStatus(
  supabase: SupabaseClient<Database>,
  paymentId: string,
  updates: {
    status?: string;
    payment_key?: string;
    approved_at?: string;
  }
) {
  const { data, error } = await supabase
    .from("toss_payments")
    .update(updates)
    .eq("id", paymentId)
    .select()
    .single();
  return { payment: data as TossPaymentRow | null, error };
}

export async function fetchTossPaymentByOrderId(
  supabase: SupabaseClient<Database>,
  orderId: string
) {
  const { data, error } = await supabase
    .from("toss_payments")
    .select("*")
    .eq("order_id", orderId)
    .single();
  return { payment: data as TossPaymentRow | null, error };
}

// P7: 알림
export type NotificationRow = Database["public"]["Tables"]["notifications"]["Row"];

export async function fetchNotifications(
  supabase: SupabaseClient<Database>,
  userId: string
) {
  const { data, error } = await supabase
    .from("notifications").select("*").eq("user_id", userId)
    .order("created_at", { ascending: false }).limit(50);
  return { notifications: (data as NotificationRow[] | null) ?? [], error };
}

export async function fetchUnreadCount(
  supabase: SupabaseClient<Database>,
  userId: string
) {
  const { count, error } = await supabase
    .from("notifications").select("*", { count: "exact", head: true })
    .eq("user_id", userId).eq("is_read", false);
  return { count: count ?? 0, error };
}

export async function markNotificationRead(
  supabase: SupabaseClient<Database>,
  notificationId: string
) {
  const { error } = await supabase
    .from("notifications").update({ is_read: true, read_at: new Date().toISOString() })
    .eq("id", notificationId);
  return { error };
}

export async function markAllNotificationsRead(
  supabase: SupabaseClient<Database>,
  userId: string
) {
  const { error } = await supabase
    .from("notifications").update({ is_read: true, read_at: new Date().toISOString() })
    .eq("user_id", userId).eq("is_read", false);
  return { error };
}

// P7: 가격 알림
export type PriceAlertRow = Database["public"]["Tables"]["price_alerts"]["Row"];

export async function fetchPriceAlerts(
  supabase: SupabaseClient<Database>,
  userId: string
) {
  const { data, error } = await supabase
    .from("price_alerts").select("*").eq("user_id", userId)
    .order("created_at", { ascending: false });
  return { alerts: (data as PriceAlertRow[] | null) ?? [], error };
}

export async function createPriceAlert(
  supabase: SupabaseClient<Database>,
  alert: { user_id: string; base_part_id: string; target_price: number; part_name?: string; price_at_creation?: number; }
) {
  const { data, error } = await supabase.from("price_alerts").insert(alert).select().single();
  return { alert: data as PriceAlertRow | null, error };
}

export async function togglePriceAlert(
  supabase: SupabaseClient<Database>,
  alertId: string,
  isActive: boolean
) {
  const { error } = await supabase
    .from("price_alerts").update({ is_active: isActive }).eq("id", alertId);
  return { error };
}

export async function deletePriceAlert(
  supabase: SupabaseClient<Database>,
  alertId: string
) {
  const { error } = await supabase.from("price_alerts").delete().eq("id", alertId);
  return { error };
}

// P6: 환불
export type RefundRow = Database["public"]["Tables"]["refunds"]["Row"];

export async function createRefund(
  supabase: SupabaseClient<Database>,
  refund: { order_id: string; user_id: string; amount: number; reason?: string; }
) {
  const { data, error } = await supabase.from("refunds").insert(refund).select().single();
  return { refund: data as RefundRow | null, error };
}

export async function fetchRefundsByUser(
  supabase: SupabaseClient<Database>,
  userId: string
) {
  const { data, error } = await supabase
    .from("refunds").select("*").eq("user_id", userId)
    .order("created_at", { ascending: false });
  return { refunds: (data as RefundRow[] | null) ?? [], error };
}

export async function fetchRefundByOrderId(
  supabase: SupabaseClient<Database>,
  orderId: string
) {
  const { data, error } = await supabase
    .from("refunds").select("*").eq("order_id", orderId).maybeSingle();
  return { refund: data as RefundRow | null, error };
}

// P6: 정산
export type SettlementRow = Database["public"]["Tables"]["settlements"]["Row"];

export async function fetchSettlements(
  supabase: SupabaseClient<Database>,
  sellerId: string,
  status?: string
) {
  let query = supabase
    .from("settlements").select("*").eq("seller_id", sellerId)
    .order("created_at", { ascending: false });
  if (status) query = query.eq("status", status);
  const { data, error } = await query;
  return { settlements: (data as SettlementRow[] | null) ?? [], error };
}

// P9: 관리자
export async function fetchAllSellRequests(
  supabase: SupabaseClient<Database>,
  status?: string
) {
  let query = supabase.from("sell_requests").select("*").order("created_at", { ascending: false });
  if (status) query = query.eq("status", status);
  const { data, error } = await query;
  return { sellRequests: (data as SellRequestRow[] | null) ?? [], error };
}

export async function updateSellRequestAdmin(
  supabase: SupabaseClient<Database>,
  requestId: string,
  updates: { status?: string; admin_note?: string; }
) {
  const { data, error } = await supabase
    .from("sell_requests").update(updates).eq("id", requestId).select().single();
  return { sellRequest: data as SellRequestRow | null, error };
}

export async function fetchAllOrders(
  supabase: SupabaseClient<Database>,
  status?: string
) {
  let query = supabase.from("orders")
    .select("*, listings(title, price, images, category)")
    .order("created_at", { ascending: false });
  if (status) query = query.eq("status", status);
  const { data, error } = await query;
  return { orders: (data as OrderWithListing[] | null) ?? [], error };
}

export async function updateOrderAdmin(
  supabase: SupabaseClient<Database>,
  orderId: string,
  updates: { status?: string; shipping_status?: string; tracking_number?: string; }
) {
  const { data, error } = await supabase
    .from("orders").update(updates).eq("id", orderId).select().single();
  return { order: data as OrderRow | null, error };
}

export type InvoiceRow = Database["public"]["Tables"]["invoices"]["Row"];

export async function fetchInvoices(
  supabase: SupabaseClient<Database>
) {
  const { data, error } = await supabase
    .from("invoices").select("*").order("created_at", { ascending: false });
  return { invoices: (data as InvoiceRow[] | null) ?? [], error };
}

export async function fetchAdminStats(
  supabase: SupabaseClient<Database>
) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayStr = today.toISOString();

  const [ordersToday, pendingSellRequests, activeListings] = await Promise.all([
    supabase.from("orders").select("total_amount").gte("created_at", todayStr),
    supabase.from("sell_requests").select("id", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("listings").select("id", { count: "exact", head: true }).eq("status", "active"),
  ]);

  const todayRevenue = (ordersToday.data ?? []).reduce((sum, o) => sum + (o.total_amount || 0), 0);
  const todayOrderCount = ordersToday.data?.length ?? 0;

  return {
    todayRevenue,
    todayOrderCount,
    pendingSellRequests: pendingSellRequests.count ?? 0,
    activeListings: activeListings.count ?? 0,
  };
}
