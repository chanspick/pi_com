import Link from "next/link";

export default function NotFound() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 px-4">
      <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#3B82F6] to-[#60A5FA] flex items-center justify-center">
        <span className="text-white text-2xl font-extrabold">π</span>
      </div>
      <h1 className="text-4xl font-extrabold text-foreground">404</h1>
      <p className="text-[15px] text-muted-foreground text-center">
        페이지를 찾을 수 없습니다.
      </p>
      <Link
        href="/"
        className="mt-2 inline-flex items-center justify-center rounded-lg bg-primary px-6 py-2.5 text-sm font-semibold text-primary-foreground hover:bg-primary/90 transition-colors"
      >
        홈으로 돌아가기
      </Link>
    </div>
  );
}
