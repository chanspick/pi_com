import type { Metadata } from "next";
import { Geist_Mono } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/providers/theme-provider";
import { QueryProvider } from "@/components/providers/query-provider";

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: {
    default: "PiCom - 검증된 중고 PC 부품 마켓플레이스",
    template: "%s | PiCom",
  },
  description:
    "PiCom은 검증된 중고 PC 부품을 안전하게 거래하는 마켓플레이스입니다. CPU, GPU, RAM, SSD 등 다양한 부품을 합리적인 가격에 만나보세요.",
  keywords: [
    "중고 PC 부품",
    "중고 그래픽카드",
    "중고 CPU",
    "PC 부품 시세",
    "검증된 중고 부품",
  ],
  openGraph: {
    type: "website",
    locale: "ko_KR",
    url: "https://picom.team",
    siteName: "PiCom",
    title: "PiCom - 검증된 중고 PC 부품 마켓플레이스",
    description:
      "PiCom은 검증된 중고 PC 부품을 안전하게 거래하는 마켓플레이스입니다. CPU, GPU, RAM, SSD 등 다양한 부품을 합리적인 가격에 만나보세요.",
  },
  twitter: {
    card: "summary_large_image",
    title: "PiCom - 검증된 중고 PC 부품 마켓플레이스",
    description:
      "PiCom은 검증된 중고 PC 부품을 안전하게 거래하는 마켓플레이스입니다. CPU, GPU, RAM, SSD 등 다양한 부품을 합리적인 가격에 만나보세요.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" suppressHydrationWarning>
      <head>
        <link
          rel="stylesheet"
          as="style"
          crossOrigin="anonymous"
          href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable.min.css"
        />
      </head>
      <body
        className={`${geistMono.variable} antialiased`}
        style={{ fontFamily: "'Pretendard Variable', Pretendard, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" }}
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <QueryProvider>{children}</QueryProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
