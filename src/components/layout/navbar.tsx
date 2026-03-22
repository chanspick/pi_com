"use client";

import Link from "next/link";
import { useAuth } from "@/hooks/use-auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { ThemeToggle } from "@/components/layout/theme-toggle";
import {
  Menu,
  Search,
  ShoppingCart,
  User,
  Heart,
  LogOut,
  Package,
} from "lucide-react";
import { useState } from "react";

const navLinks = [
  { name: "매물", href: "/listings" },
  { name: "부품 시세", href: "/parts" },
];

const categories = [
  { name: "CPU", href: "/listings?category=cpu" },
  { name: "GPU", href: "/listings?category=gpu" },
  { name: "RAM", href: "/listings?category=ram" },
  { name: "SSD", href: "/listings?category=ssd" },
  { name: "메인보드", href: "/listings?category=mainboard" },
  { name: "파워", href: "/listings?category=power" },
  { name: "케이스", href: "/listings?category=case" },
  { name: "쿨러", href: "/listings?category=cooler" },
];

function PiComLogo() {
  return (
    <Link href="/" className="flex items-center gap-2.5 group">
      <div className="w-9 h-9 rounded-[10px] bg-gradient-to-br from-[#3B82F6] to-[#60A5FA] flex items-center justify-center shadow-[0_2px_8px_rgba(59,130,246,0.4)] group-hover:shadow-[0_2px_12px_rgba(59,130,246,0.5)] transition-shadow">
        <span className="text-white text-base font-extrabold leading-none">π</span>
      </div>
      <span className="text-[22px] font-extrabold tracking-[-0.02em] text-foreground">
        PiCom
      </span>
    </Link>
  );
}

export function Navbar() {
  const { user, loading, signOut } = useAuth();
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-16 items-center gap-4 px-4 mx-auto max-w-7xl">
        {/* 모바일 메뉴 */}
        <Sheet open={open} onOpenChange={setOpen}>
          <SheetTrigger
            className="md:hidden inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all cursor-pointer disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground h-9 w-9"
          >
            <Menu className="h-5 w-5" />
            <span className="sr-only">메뉴</span>
          </SheetTrigger>
          <SheetContent side="left">
            <SheetHeader>
              <SheetTitle>
                <div className="flex items-center gap-2">
                  <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-[#3B82F6] to-[#60A5FA] flex items-center justify-center">
                    <span className="text-white text-xs font-extrabold">π</span>
                  </div>
                  PiCom
                </div>
              </SheetTitle>
            </SheetHeader>
            <nav className="flex flex-col gap-2 mt-4">
              {categories.map((cat) => (
                <Link
                  key={cat.name}
                  href={cat.href}
                  className="px-3 py-2 text-sm rounded-md hover:bg-accent"
                  onClick={() => setOpen(false)}
                >
                  {cat.name}
                </Link>
              ))}
            </nav>
          </SheetContent>
        </Sheet>

        {/* 로고 */}
        <PiComLogo />

        {/* 데스크톱 카테고리 */}
        <nav className="hidden md:flex items-center gap-1">
          {categories.map((cat) => (
            <Link
              key={cat.name}
              href={cat.href}
              className="px-3 py-1.5 text-[13px] font-medium rounded-lg hover:bg-accent text-muted-foreground hover:text-foreground transition-colors"
            >
              {cat.name}
            </Link>
          ))}
        </nav>

        {/* 검색 바 */}
        <div className="hidden md:flex flex-1 max-w-sm ml-auto">
          <div className="relative w-full">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="부품명, 모델명으로 검색"
              className="pl-9 h-10 rounded-lg border-[1.5px]"
            />
          </div>
        </div>

        {/* 우측 메뉴 */}
        <div className="flex items-center gap-2 ml-auto md:ml-0">
          <ThemeToggle />

          {loading ? (
            <div className="h-8 w-8 rounded-full bg-muted animate-pulse" />
          ) : user ? (
            <>
              <Link href="/cart">
                <Button variant="ghost" size="icon">
                  <ShoppingCart className="h-4 w-4" />
                  <span className="sr-only">장바구니</span>
                </Button>
              </Link>

              <DropdownMenu>
                <DropdownMenuTrigger className="inline-flex items-center justify-center rounded-full h-9 w-9 hover:bg-accent cursor-pointer">
                  <Avatar className="h-8 w-8">
                    <AvatarImage src={user.user_metadata?.avatar_url} />
                    <AvatarFallback className="bg-primary/10 text-primary text-sm font-semibold">
                      {user.user_metadata?.full_name?.[0] || user.email?.[0]?.toUpperCase() || "U"}
                    </AvatarFallback>
                  </Avatar>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-48">
                  <DropdownMenuItem>
                    <Link href="/my-page" className="flex items-center gap-2">
                      <User className="h-4 w-4" />
                      마이페이지
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuItem>
                    <Link href="/orders" className="flex items-center gap-2">
                      <Package className="h-4 w-4" />
                      주문내역
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuItem>
                    <Link href="/my-page/favorites" className="flex items-center gap-2">
                      <Heart className="h-4 w-4" />
                      즐겨찾기
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onClick={signOut} className="flex items-center gap-2">
                    <LogOut className="h-4 w-4" />
                    로그아웃
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </>
          ) : (
            <div className="flex items-center gap-2">
              <Link href="/login">
                <Button variant="ghost" size="sm">
                  로그인
                </Button>
              </Link>
              <Link href="/signup">
                <Button
                  size="sm"
                  className="text-[13px] font-semibold bg-gradient-to-r from-[#2563EB] to-[#3B82F6] hover:from-[#1D4ED8] hover:to-[#2563EB] shadow-[0_1px_3px_rgba(37,99,235,0.3)]"
                >
                  회원가입
                </Button>
              </Link>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
