export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: { id: string; email: string | null; display_name: string | null; avatar_url: string | null; phone: string | null; is_admin: boolean; old_firebase_uid: string | null; provider: string | null; providers: string[]; last_login_at: string | null; created_at: string; updated_at: string; };
        Insert: { id: string; email?: string | null; };
        Update: { email?: string | null; display_name?: string | null; avatar_url?: string | null; phone?: string | null; provider?: string | null; providers?: string[]; last_login_at?: string | null; };
        Relationships: [];
      };
      base_parts: {
        Row: { id: string; category: string; name: string; brand: string | null; model: string | null; specs: Json; image_url: string | null; description: string | null; lowest_price: number; average_price: number; listing_count: number; created_at: string; updated_at: string; };
        Insert: { id?: string; category: string; name: string; };
        Update: { name?: string; };
        Relationships: [];
      };
      listings: {
        Row: { id: string; seller_id: string; base_part_id: string | null; title: string; description: string | null; price: number; original_price: number | null; category: string; status: string; condition: string | null; condition_score: number | null; images: string[]; specs: Json; view_count: number; favorite_count: number; is_featured: boolean; expires_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; seller_id: string; title: string; price: number; category: string; description?: string | null; original_price?: number | null; condition?: string | null; condition_score?: number | null; images?: string[]; base_part_id?: string | null; specs?: Json; status?: string; };
        Update: { title?: string; price?: number; status?: string; description?: string | null; original_price?: number | null; condition?: string | null; condition_score?: number | null; images?: string[]; base_part_id?: string | null; specs?: Json; };
        Relationships: [
          { foreignKeyName: "listings_seller_id_fkey"; columns: ["seller_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
          { foreignKeyName: "listings_base_part_id_fkey"; columns: ["base_part_id"]; isOneToOne: false; referencedRelation: "base_parts"; referencedColumns: ["id"]; },
        ];
      };
      orders: {
        Row: { id: string; buyer_id: string; seller_id: string; listing_id: string; status: string; shipping_status: string; total_amount: number; shipping_fee: number; shipping_address: Json | null; tracking_number: string | null; notes: string | null; confirmed_at: string | null; shipped_at: string | null; delivered_at: string | null; cancelled_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; buyer_id: string; seller_id: string; listing_id: string; total_amount: number; shipping_fee?: number; shipping_address?: Json | null; shipping_status?: string; notes?: string | null; };
        Update: { status?: string; tracking_number?: string | null; shipping_status?: string; shipping_address?: Json | null; notes?: string | null; confirmed_at?: string | null; shipped_at?: string | null; delivered_at?: string | null; cancelled_at?: string | null; };
        Relationships: [
          { foreignKeyName: "orders_buyer_id_fkey"; columns: ["buyer_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
          { foreignKeyName: "orders_seller_id_fkey"; columns: ["seller_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
          { foreignKeyName: "orders_listing_id_fkey"; columns: ["listing_id"]; isOneToOne: false; referencedRelation: "listings"; referencedColumns: ["id"]; },
        ];
      };
      toss_payments: {
        Row: { id: string; order_id: string; payment_key: string | null; order_name: string | null; amount: number; status: string; method: string | null; requested_at: string | null; approved_at: string | null; cancelled_at: string | null; cancel_reason: string | null; receipt_url: string | null; raw_data: Json | null; created_at: string; updated_at: string; };
        Insert: { id?: string; order_id: string; amount: number; payment_key?: string | null; order_name?: string | null; status?: string; method?: string | null; };
        Update: { status?: string; payment_key?: string | null; amount?: number; method?: string | null; requested_at?: string | null; approved_at?: string | null; cancelled_at?: string | null; cancel_reason?: string | null; receipt_url?: string | null; raw_data?: Json | null; };
        Relationships: [
          { foreignKeyName: "toss_payments_order_id_fkey"; columns: ["order_id"]; isOneToOne: false; referencedRelation: "orders"; referencedColumns: ["id"]; },
        ];
      };
      cart_items: {
        Row: { id: string; user_id: string; listing_id: string; quantity: number; created_at: string; };
        Insert: { id?: string; user_id: string; listing_id: string; };
        Update: { quantity?: number; };
        Relationships: [
          { foreignKeyName: "cart_items_user_id_fkey"; columns: ["user_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
          { foreignKeyName: "cart_items_listing_id_fkey"; columns: ["listing_id"]; isOneToOne: false; referencedRelation: "listings"; referencedColumns: ["id"]; },
        ];
      };
      favorites: {
        Row: { id: string; user_id: string; listing_id: string; created_at: string; };
        Insert: { id?: string; user_id: string; listing_id: string; };
        Update: Record<string, never>;
        Relationships: [
          { foreignKeyName: "favorites_user_id_fkey"; columns: ["user_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
          { foreignKeyName: "favorites_listing_id_fkey"; columns: ["listing_id"]; isOneToOne: false; referencedRelation: "listings"; referencedColumns: ["id"]; },
        ];
      };
      price_history: {
        Row: { id: string; base_part_id: string; price: number; lowest_price: number | null; average_price: number | null; listing_count: number | null; source: string | null; recorded_at: string; created_at: string; };
        Insert: { id?: string; base_part_id: string; price: number; };
        Update: { price?: number; };
        Relationships: [
          { foreignKeyName: "price_history_base_part_id_fkey"; columns: ["base_part_id"]; isOneToOne: false; referencedRelation: "base_parts"; referencedColumns: ["id"]; },
        ];
      };
      price_alerts: {
        Row: { id: string; user_id: string; base_part_id: string; target_price: number; is_active: boolean; part_name: string | null; price_at_creation: number | null; last_checked_at: string | null; triggered_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; user_id: string; base_part_id: string; target_price: number; part_name?: string | null; price_at_creation?: number | null; };
        Update: { target_price?: number; is_active?: boolean; last_checked_at?: string | null; };
        Relationships: [
          { foreignKeyName: "price_alerts_user_id_fkey"; columns: ["user_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
          { foreignKeyName: "price_alerts_base_part_id_fkey"; columns: ["base_part_id"]; isOneToOne: false; referencedRelation: "base_parts"; referencedColumns: ["id"]; },
        ];
      };
      notifications: {
        Row: { id: string; user_id: string; title: string; body: string | null; type: string | null; data: Json; is_read: boolean; related_order_id: string | null; related_listing_id: string | null; related_sell_request_id: string | null; related_refund_id: string | null; related_dragon_ball_id: string | null; read_at: string | null; created_at: string; };
        Insert: { id?: string; user_id: string; title: string; type?: string | null; related_order_id?: string | null; related_listing_id?: string | null; };
        Update: { is_read?: boolean; read_at?: string | null; };
        Relationships: [
          { foreignKeyName: "notifications_user_id_fkey"; columns: ["user_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
        ];
      };
      dragon_balls: {
        Row: { id: string; user_id: string; amount: number; reason: string | null; status: string; storage_type: string; accumulated_fee: number; agreed_to_terms: boolean; agreed_at: string | null; sale_price: number | null; consignment_converted_at: string | null; revenue_returned: boolean; batch_shipment_id: string | null; expires_at: string | null; used_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; user_id: string; amount: number; storage_type?: string; };
        Update: { status?: string; storage_type?: string; accumulated_fee?: number; sale_price?: number | null; };
        Relationships: [
          { foreignKeyName: "dragon_balls_user_id_fkey"; columns: ["user_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
        ];
      };
      batch_shipments: {
        Row: { id: string; user_id: string; dragon_ball_ids: string[]; recipient_name: string; phone: string; shipping_address: Json; shipping_cost: number; additional_services: Json; tracking_number: string | null; status: string; created_at: string; updated_at: string; };
        Insert: { id?: string; user_id: string; recipient_name: string; phone: string; shipping_address: Json; dragon_ball_ids?: string[]; };
        Update: { status?: string; tracking_number?: string | null; };
        Relationships: [
          { foreignKeyName: "batch_shipments_user_id_fkey"; columns: ["user_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
        ];
      };
      refunds: {
        Row: { id: string; order_id: string; user_id: string; amount: number; reason: string | null; status: string; approved_at: string | null; completed_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; order_id: string; user_id: string; amount: number; reason?: string | null; };
        Update: { status?: string; approved_at?: string | null; completed_at?: string | null; };
        Relationships: [
          { foreignKeyName: "refunds_order_id_fkey"; columns: ["order_id"]; isOneToOne: false; referencedRelation: "orders"; referencedColumns: ["id"]; },
          { foreignKeyName: "refunds_user_id_fkey"; columns: ["user_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
        ];
      };
      invoices: {
        Row: { id: string; order_id: string; user_id: string; invoice_number: string | null; pdf_url: string | null; qr_code: string | null; warranty_start_date: string | null; warranty_end_date: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; order_id: string; user_id: string; };
        Update: { pdf_url?: string | null; };
        Relationships: [
          { foreignKeyName: "invoices_order_id_fkey"; columns: ["order_id"]; isOneToOne: false; referencedRelation: "orders"; referencedColumns: ["id"]; },
          { foreignKeyName: "invoices_user_id_fkey"; columns: ["user_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
        ];
      };
      settlements: {
        Row: { id: string; seller_id: string; order_id: string; amount: number; fee: number; net_amount: number; status: string; settled_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; seller_id: string; order_id: string; amount: number; net_amount: number; };
        Update: { status?: string; };
        Relationships: [
          { foreignKeyName: "settlements_seller_id_fkey"; columns: ["seller_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
          { foreignKeyName: "settlements_order_id_fkey"; columns: ["order_id"]; isOneToOne: false; referencedRelation: "orders"; referencedColumns: ["id"]; },
        ];
      };
      addresses: {
        Row: { id: string; user_id: string; label: string | null; recipient_name: string; phone: string; postal_code: string; address_line1: string; address_line2: string | null; is_default: boolean; created_at: string; updated_at: string; };
        Insert: { id?: string; user_id: string; recipient_name: string; phone: string; postal_code: string; address_line1: string; address_line2?: string | null; is_default?: boolean; label?: string | null; };
        Update: { recipient_name?: string; phone?: string; postal_code?: string; address_line1?: string; address_line2?: string | null; is_default?: boolean; label?: string | null; };
        Relationships: [
          { foreignKeyName: "addresses_user_id_fkey"; columns: ["user_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
        ];
      };
      account_deletions: {
        Row: { id: string; user_id: string; reason: string | null; requested_at: string; processed_at: string | null; created_at: string; };
        Insert: { id?: string; user_id: string; reason?: string | null; requested_at?: string; };
        Update: { processed_at?: string | null; };
        Relationships: [
          { foreignKeyName: "account_deletions_user_id_fkey"; columns: ["user_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
        ];
      };
      sell_requests: {
        Row: { id: string; user_id: string; category: string; title: string; description: string | null; desired_price: number | null; images: string[]; specs: Json; status: string; admin_note: string | null; listing_id: string | null; is_secondhand: boolean; has_warranty: boolean; warranty_months_left: number | null; reviewed_at: string | null; completed_at: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; user_id: string; category: string; title: string; description?: string | null; desired_price?: number | null; images?: string[]; specs?: Json; is_secondhand?: boolean; has_warranty?: boolean; warranty_months_left?: number | null; };
        Update: { status?: string; admin_note?: string | null; is_secondhand?: boolean; has_warranty?: boolean; warranty_months_left?: number | null; description?: string | null; desired_price?: number | null; images?: string[]; specs?: Json; };
        Relationships: [
          { foreignKeyName: "sell_requests_user_id_fkey"; columns: ["user_id"]; isOneToOne: false; referencedRelation: "profiles"; referencedColumns: ["id"]; },
        ];
      };
      verification_results: {
        Row: { id: string; listing_id: string; inspector_name: string | null; inspected_at: string | null; inspection_note: string | null; condition_score: number; condition_grade: string; benchmark_scores: Json; inspection_photo_urls: string[]; temperature_data: Json; fan_status: string | null; created_at: string; updated_at: string; };
        Insert: { id?: string; listing_id: string; condition_score: number; condition_grade: string; inspector_name?: string | null; inspection_note?: string | null; benchmark_scores?: Json; inspection_photo_urls?: string[]; temperature_data?: Json; fan_status?: string | null; };
        Update: { condition_score?: number; condition_grade?: string; inspector_name?: string | null; inspection_note?: string | null; benchmark_scores?: Json; inspection_photo_urls?: string[]; temperature_data?: Json; fan_status?: string | null; };
        Relationships: [
          { foreignKeyName: "verification_results_listing_id_fkey"; columns: ["listing_id"]; isOneToOne: true; referencedRelation: "listings"; referencedColumns: ["id"]; },
        ];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
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
    CompositeTypes: Record<string, never>;
  };
};
