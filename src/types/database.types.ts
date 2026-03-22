export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: { id: string; email: string | null; display_name: string | null; avatar_url: string | null; phone: string | null; is_admin: boolean; old_firebase_uid: string | null; provider: string | null; providers: string[]; last_login_at: string | null; created_at: string; updated_at: string; };
        Insert: { id: string; email?: string | null; };
        Update: { email?: string | null; display_name?: string | null; provider?: string | null; providers?: string[]; last_login_at?: string | null; };
      };
      base_parts: {
        Row: { id: string; category: string; name: string; brand: string | null; model: string | null; specs: Json; image_url: string | null; description: string | null; lowest_price: number; average_price: number; listing_count: number; created_at: string; updated_at: string; };
        Insert: { id?: string; category: string; name: string; };
        Update: { name?: string; };
      };
      listings: {
        Row: { id: string; seller_id: string; base_part_id: string | null; title: string; description: string | null; price: number; original_price: number | null; category: string; status: string; condition: string | null; condition_score: number | null; images: string[]; specs: Json; view_count: number; favorite_count: number; is_featured: boolean; expires_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; seller_id: string; title: string; price: number; category: string; };
        Update: { title?: string; price?: number; status?: string; };
      };
      orders: {
        Row: { id: string; buyer_id: string; seller_id: string; listing_id: string; status: string; shipping_status: string; total_amount: number; shipping_fee: number; shipping_address: Json | null; tracking_number: string | null; notes: string | null; confirmed_at: string | null; shipped_at: string | null; delivered_at: string | null; cancelled_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; buyer_id: string; seller_id: string; listing_id: string; total_amount: number; };
        Update: { status?: string; tracking_number?: string | null; };
      };
      toss_payments: {
        Row: { id: string; order_id: string; payment_key: string | null; order_name: string | null; amount: number; status: string; method: string | null; requested_at: string | null; approved_at: string | null; cancelled_at: string | null; cancel_reason: string | null; receipt_url: string | null; raw_data: Json | null; created_at: string; updated_at: string; };
        Insert: { id?: string; order_id: string; amount: number; };
        Update: { status?: string; payment_key?: string | null; };
      };
      cart_items: {
        Row: { id: string; user_id: string; listing_id: string; quantity: number; created_at: string; };
        Insert: { id?: string; user_id: string; listing_id: string; };
        Update: { quantity?: number; };
      };
      favorites: {
        Row: { id: string; user_id: string; listing_id: string; created_at: string; };
        Insert: { id?: string; user_id: string; listing_id: string; };
        Update: Record<string, never>;
      };
      price_history: {
        Row: { id: string; base_part_id: string; price: number; lowest_price: number | null; average_price: number | null; listing_count: number | null; source: string | null; recorded_at: string; created_at: string; };
        Insert: { id?: string; base_part_id: string; price: number; };
        Update: { price?: number; };
      };
      price_alerts: {
        Row: { id: string; user_id: string; base_part_id: string; target_price: number; is_active: boolean; part_name: string | null; price_at_creation: number | null; last_checked_at: string | null; triggered_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; user_id: string; base_part_id: string; target_price: number; part_name?: string | null; price_at_creation?: number | null; };
        Update: { target_price?: number; is_active?: boolean; last_checked_at?: string | null; };
      };
      notifications: {
        Row: { id: string; user_id: string; title: string; body: string | null; type: string | null; data: Json; is_read: boolean; related_order_id: string | null; related_listing_id: string | null; related_sell_request_id: string | null; related_refund_id: string | null; related_dragon_ball_id: string | null; read_at: string | null; created_at: string; };
        Insert: { id?: string; user_id: string; title: string; type?: string | null; related_order_id?: string | null; related_listing_id?: string | null; };
        Update: { is_read?: boolean; read_at?: string | null; };
      };
      dragon_balls: {
        Row: { id: string; user_id: string; amount: number; reason: string | null; status: string; storage_type: string; accumulated_fee: number; agreed_to_terms: boolean; agreed_at: string | null; sale_price: number | null; consignment_converted_at: string | null; revenue_returned: boolean; batch_shipment_id: string | null; expires_at: string | null; used_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; user_id: string; amount: number; storage_type?: string; };
        Update: { status?: string; storage_type?: string; accumulated_fee?: number; sale_price?: number | null; };
      };
      batch_shipments: {
        Row: { id: string; user_id: string; dragon_ball_ids: string[]; recipient_name: string; phone: string; shipping_address: Json; shipping_cost: number; additional_services: Json; tracking_number: string | null; status: string; created_at: string; updated_at: string; };
        Insert: { id?: string; user_id: string; recipient_name: string; phone: string; shipping_address: Json; dragon_ball_ids?: string[]; };
        Update: { status?: string; tracking_number?: string | null; };
      };
      refunds: {
        Row: { id: string; order_id: string; user_id: string; amount: number; reason: string | null; status: string; approved_at: string | null; completed_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; order_id: string; user_id: string; amount: number; reason?: string | null; };
        Update: { status?: string; approved_at?: string | null; completed_at?: string | null; };
      };
      invoices: {
        Row: { id: string; order_id: string; user_id: string; invoice_number: string | null; pdf_url: string | null; qr_code: string | null; warranty_start_date: string | null; warranty_end_date: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; order_id: string; user_id: string; };
        Update: { pdf_url?: string | null; };
      };
      settlements: {
        Row: { id: string; seller_id: string; order_id: string; amount: number; fee: number; net_amount: number; status: string; settled_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; seller_id: string; order_id: string; amount: number; net_amount: number; };
        Update: { status?: string; };
      };
      addresses: {
        Row: { id: string; user_id: string; label: string | null; recipient_name: string; phone: string; postal_code: string; address_line1: string; address_line2: string | null; is_default: boolean; created_at: string; updated_at: string; };
        Insert: { id?: string; user_id: string; recipient_name: string; phone: string; postal_code: string; address_line1: string; };
        Update: { recipient_name?: string; is_default?: boolean; };
      };
      account_deletions: {
        Row: { id: string; user_id: string; reason: string | null; requested_at: string; processed_at: string | null; created_at: string; };
        Insert: { id?: string; user_id: string; };
        Update: { processed_at?: string | null; };
      };
      sell_requests: {
        Row: { id: string; user_id: string; category: string; title: string; description: string | null; desired_price: number | null; images: string[]; specs: Json; status: string; admin_note: string | null; listing_id: string | null; is_secondhand: boolean; has_warranty: boolean; warranty_months_left: number | null; reviewed_at: string | null; completed_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; user_id: string; category: string; title: string; is_secondhand?: boolean; has_warranty?: boolean; };
        Update: { status?: string; admin_note?: string | null; is_secondhand?: boolean; has_warranty?: boolean; warranty_months_left?: number | null; };
      };
    };
    Enums: {
      part_category: "cpu" | "gpu" | "ram" | "ssd" | "mainboard" | "power" | "case" | "cooler";
      listing_status: "draft" | "active" | "reserved" | "sold" | "expired" | "deleted";
      order_status: "pending" | "confirmed" | "shipping" | "delivered" | "cancelled" | "refunded";
      payment_status: "pending" | "paid" | "failed" | "cancelled" | "refunded";
      shipping_status: "preparing" | "shipped" | "in_transit" | "delivered" | "returned";
      sell_request_status: "pending" | "reviewing" | "approved" | "rejected" | "completed";
      dragon_ball_status: "active" | "used" | "expired";
      settlement_status: "pending" | "processing" | "completed" | "failed";
      batch_shipment_status: "pending" | "processing" | "shipped" | "delivered" | "cancelled";
      refund_status: "pending" | "approved" | "rejected" | "completed";
      dragon_ball_storage_type: "general" | "rental";
    };
  };
};
