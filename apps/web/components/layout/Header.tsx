"use client";

import Link from "next/link";
import { Shield, User, LogOut, List } from "lucide-react";
import { useAuth } from "@/lib/auth/AuthContext";

export function Header() {
  const { user, loading, signOut } = useAuth();

  return (
    <header className="sticky top-0 z-50 w-full border-b border-gray-200 bg-white/95 backdrop-blur supports-[backdrop-filter]:bg-white/60">
      <div className="container mx-auto flex h-14 items-center px-4">
        <Link href="/" className="flex items-center space-x-2">
          <Shield className="h-6 w-6 text-blue-600" />
          <span className="font-bold text-lg">PiComputer</span>
        </Link>
        <nav className="ml-auto flex items-center space-x-3">
          {!loading && user ? (
            <>
              <Link
                href="/my"
                className="flex items-center gap-1.5 text-sm text-gray-600 hover:text-gray-900"
              >
                <List className="h-4 w-4" />
                <span className="hidden sm:inline">내 보증</span>
              </Link>
              <div className="flex items-center gap-1.5 text-sm text-gray-500">
                <User className="h-4 w-4" />
                <span className="hidden sm:inline max-w-[100px] truncate">
                  {user.displayName || user.email || "사용자"}
                </span>
              </div>
              <button
                onClick={signOut}
                className="flex items-center gap-1 text-sm text-gray-400 hover:text-gray-600"
                title="로그아웃"
              >
                <LogOut className="h-4 w-4" />
              </button>
            </>
          ) : (
            <span className="text-sm text-gray-500">AS 보증 서비스</span>
          )}
        </nav>
      </div>
    </header>
  );
}
