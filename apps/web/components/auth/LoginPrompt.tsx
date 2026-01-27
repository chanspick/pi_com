"use client";

import { useState } from "react";
import { useAuth } from "@/lib/auth/AuthContext";
import { redirectToKakaoLogin } from "@/lib/auth/kakao";
import { PhoneLoginForm } from "./PhoneLoginForm";
import { LogIn, MessageCircle, Phone, X } from "lucide-react";
import { Button } from "@/components/ui/button";

interface LoginPromptProps {
  redirectPath?: string;
  onClose?: () => void;
  message?: string;
}

export function LoginPrompt({ redirectPath, onClose, message }: LoginPromptProps) {
  const { user } = useAuth();
  const [showPhoneLogin, setShowPhoneLogin] = useState(false);

  if (user) return null;

  return (
    <div className="bg-white rounded-xl border p-5">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <LogIn className="h-5 w-5 text-blue-600" />
          <h3 className="font-semibold">로그인</h3>
        </div>
        {onClose && (
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <X className="h-5 w-5" />
          </button>
        )}
      </div>

      {message && (
        <p className="text-sm text-gray-500 mb-4">{message}</p>
      )}

      {!showPhoneLogin ? (
        <div className="space-y-3">
          <Button
            onClick={() => redirectToKakaoLogin(redirectPath)}
            className="w-full py-5 bg-[#FEE500] hover:bg-[#FDD835] text-[#191919] font-medium"
          >
            <MessageCircle className="h-5 w-5 mr-2" />
            카카오로 로그인
          </Button>

          <Button
            onClick={() => setShowPhoneLogin(true)}
            variant="outline"
            className="w-full py-5"
          >
            <Phone className="h-5 w-5 mr-2" />
            전화번호로 로그인
          </Button>
        </div>
      ) : (
        <div>
          <PhoneLoginForm />
          <button
            onClick={() => setShowPhoneLogin(false)}
            className="mt-3 text-sm text-gray-500 hover:text-gray-700 w-full text-center"
          >
            다른 방법으로 로그인
          </button>
        </div>
      )}
    </div>
  );
}
