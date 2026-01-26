"use client";

import Link from "next/link";
import { Shield } from "lucide-react";

export function Header() {
  return (
    <header className="sticky top-0 z-50 w-full border-b border-gray-200 bg-white/95 backdrop-blur supports-[backdrop-filter]:bg-white/60">
      <div className="container mx-auto flex h-14 items-center px-4">
        <Link href="/" className="flex items-center space-x-2">
          <Shield className="h-6 w-6 text-blue-600" />
          <span className="font-bold text-lg">PiComputer</span>
        </Link>
        <nav className="ml-auto flex items-center space-x-4">
          <span className="text-sm text-gray-500">AS 보증 서비스</span>
        </nav>
      </div>
    </header>
  );
}
