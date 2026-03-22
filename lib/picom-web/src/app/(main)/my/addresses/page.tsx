"use client";

import { useState } from "react";
import Link from "next/link";
import { useAuth } from "@/hooks/use-auth";
import {
  useAddresses,
  useCreateAddress,
  useUpdateAddress,
  useDeleteAddress,
} from "@/hooks/use-addresses";
import type { AddressRow } from "@/hooks/use-addresses";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { ArrowLeft, MapPin, Plus, Trash2, Star } from "lucide-react";

interface AddressFormData {
  recipient_name: string;
  phone: string;
  postal_code: string;
  address_line1: string;
  address_line2: string;
  is_default: boolean;
}

const emptyForm: AddressFormData = {
  recipient_name: "",
  phone: "",
  postal_code: "",
  address_line1: "",
  address_line2: "",
  is_default: false,
};

export default function AddressesPage() {
  const { user, loading: authLoading } = useAuth();
  const { data: addresses, isLoading } = useAddresses(user?.id);
  const createMutation = useCreateAddress();
  const updateMutation = useUpdateAddress();
  const deleteMutation = useDeleteAddress();

  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<AddressFormData>(emptyForm);

  const handleOpenAdd = () => {
    setEditingId(null);
    setForm(emptyForm);
    setShowForm(true);
  };

  const handleOpenEdit = (address: AddressRow) => {
    setEditingId(address.id);
    setForm({
      recipient_name: address.recipient_name ?? "",
      phone: address.phone ?? "",
      postal_code: address.postal_code ?? "",
      address_line1: address.address_line1 ?? "",
      address_line2: address.address_line2 ?? "",
      is_default: address.is_default ?? false,
    });
    setShowForm(true);
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditingId(null);
    setForm(emptyForm);
  };

  const handleSave = async () => {
    if (!user) return;
    if (!form.recipient_name || !form.phone || !form.postal_code || !form.address_line1) return;

    if (editingId) {
      await updateMutation.mutateAsync({
        addressId: editingId,
        userId: user.id,
        updates: {
          recipient_name: form.recipient_name,
          phone: form.phone,
          postal_code: form.postal_code,
          address_line1: form.address_line1,
          address_line2: form.address_line2,
          is_default: form.is_default,
        },
      });
    } else {
      await createMutation.mutateAsync({
        user_id: user.id,
        recipient_name: form.recipient_name,
        phone: form.phone,
        postal_code: form.postal_code,
        address_line1: form.address_line1,
        address_line2: form.address_line2 || undefined,
        is_default: form.is_default,
      });
    }

    handleCancel();
  };

  const handleDelete = async (addressId: string) => {
    if (!user) return;
    await deleteMutation.mutateAsync({ addressId, userId: user.id });
  };

  const handleSetDefault = async (addressId: string) => {
    if (!user) return;
    await updateMutation.mutateAsync({
      addressId,
      userId: user.id,
      updates: { is_default: true },
    });
  };

  const isSaving = createMutation.isPending || updateMutation.isPending;

  if (authLoading || isLoading) {
    return (
      <div className="container mx-auto max-w-2xl px-4 py-10">
        <div className="animate-pulse space-y-4">
          <div className="h-8 w-48 bg-muted rounded" />
          <div className="h-32 bg-muted rounded-xl" />
          <div className="h-32 bg-muted rounded-xl" />
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="container mx-auto max-w-2xl px-4 py-10 text-center">
        <p className="text-muted-foreground">로그인이 필요합니다.</p>
        <Link href="/login">
          <Button className="mt-4">로그인</Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="container mx-auto max-w-2xl px-4 py-10">
      {/* 헤더 */}
      <div className="flex items-center gap-3 mb-6">
        <Link
          href="/my"
          className="flex items-center justify-center w-9 h-9 rounded-lg hover:bg-muted transition-colors"
          aria-label="뒤로 가기"
        >
          <ArrowLeft className="h-5 w-5" />
        </Link>
        <div className="flex-1">
          <h1 className="text-[22px] font-bold">배송지 관리</h1>
          <p className="text-[13px] text-muted-foreground mt-0.5">
            배송지를 추가하고 관리하세요
          </p>
        </div>
        {!showForm && (
          <Button onClick={handleOpenAdd} size="sm" className="gap-1.5">
            <Plus className="h-4 w-4" />
            새 배송지 추가
          </Button>
        )}
      </div>

      {/* 추가/수정 폼 */}
      {showForm && (
        <Card className="mb-6">
          <CardContent className="space-y-4">
            <h3 className="font-semibold text-[15px]">
              {editingId ? "배송지 수정" : "새 배송지 추가"}
            </h3>
            <Separator />
            <div className="space-y-3">
              <div>
                <label className="text-[13px] font-medium text-foreground mb-1.5 block">
                  수령인
                </label>
                <Input
                  placeholder="수령인 이름"
                  value={form.recipient_name}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, recipient_name: e.target.value }))
                  }
                />
              </div>
              <div>
                <label className="text-[13px] font-medium text-foreground mb-1.5 block">
                  연락처
                </label>
                <Input
                  placeholder="010-0000-0000"
                  value={form.phone}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, phone: e.target.value }))
                  }
                />
              </div>
              <div>
                <label className="text-[13px] font-medium text-foreground mb-1.5 block">
                  우편번호
                </label>
                <div className="flex gap-2">
                  <Input
                    placeholder="우편번호"
                    value={form.postal_code}
                    onChange={(e) =>
                      setForm((prev) => ({ ...prev, postal_code: e.target.value }))
                    }
                    className="flex-1"
                  />
                  <Button variant="outline" size="default" type="button">
                    우편번호 검색
                  </Button>
                </div>
              </div>
              <div>
                <label className="text-[13px] font-medium text-foreground mb-1.5 block">
                  기본 주소
                </label>
                <Input
                  placeholder="기본 주소"
                  value={form.address_line1}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, address_line1: e.target.value }))
                  }
                />
              </div>
              <div>
                <label className="text-[13px] font-medium text-foreground mb-1.5 block">
                  상세 주소
                </label>
                <Input
                  placeholder="상세 주소"
                  value={form.address_line2}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, address_line2: e.target.value }))
                  }
                />
              </div>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={form.is_default}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, is_default: e.target.checked }))
                  }
                  className="h-4 w-4 rounded border-border accent-primary"
                />
                <span className="text-[13px] font-medium">
                  기본 배송지로 설정
                </span>
              </label>
            </div>
            <div className="flex gap-2 pt-2">
              <Button
                onClick={handleSave}
                disabled={
                  isSaving ||
                  !form.recipient_name ||
                  !form.phone ||
                  !form.postal_code ||
                  !form.address_line1
                }
                className="flex-1"
              >
                {isSaving ? "저장 중..." : "저장"}
              </Button>
              <Button variant="outline" onClick={handleCancel} className="flex-1">
                취소
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* 배송지 목록 */}
      {(!addresses || addresses.length === 0) && !showForm ? (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <div className="w-14 h-14 rounded-full bg-muted flex items-center justify-center mb-4">
            <MapPin className="h-6 w-6 text-muted-foreground" />
          </div>
          <p className="text-[15px] font-medium text-muted-foreground">
            등록된 배송지가 없습니다
          </p>
          <p className="text-[13px] text-muted-foreground mt-1">
            새 배송지를 추가해 주세요
          </p>
          <Button onClick={handleOpenAdd} className="mt-4 gap-1.5">
            <Plus className="h-4 w-4" />
            배송지 추가
          </Button>
        </div>
      ) : (
        <div className="space-y-3">
          {addresses?.map((address) => (
            <Card key={address.id}>
              <CardContent>
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1.5">
                      <span className="font-semibold text-[15px]">
                        {address.recipient_name}
                      </span>
                      {address.is_default && (
                        <Badge variant="default" className="text-[11px]">
                          기본 배송지
                        </Badge>
                      )}
                    </div>
                    <p className="text-[13px] text-muted-foreground mb-1">
                      {address.phone}
                    </p>
                    <p className="text-[13px] text-foreground">
                      ({address.postal_code}) {address.address_line1}
                      {address.address_line2 && ` ${address.address_line2}`}
                    </p>
                  </div>
                </div>
                <Separator className="my-3" />
                <div className="flex items-center gap-2">
                  {!address.is_default && (
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleSetDefault(address.id)}
                      disabled={updateMutation.isPending}
                      className="gap-1"
                    >
                      <Star className="h-3.5 w-3.5" />
                      기본 배송지로 설정
                    </Button>
                  )}
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleOpenEdit(address)}
                  >
                    수정
                  </Button>
                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => handleDelete(address.id)}
                    disabled={deleteMutation.isPending}
                    className="gap-1"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                    삭제
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
