"use client";

export function Footer() {
  return (
    <footer className="border-t border-gray-200 bg-gray-50">
      <div className="container mx-auto px-4 py-6">
        <div className="flex flex-col items-center justify-between gap-4 md:flex-row">
          <div className="text-center md:text-left">
            <p className="text-sm text-gray-500">
              &copy; {new Date().getFullYear()} PiComputer. All rights reserved.
            </p>
          </div>
          <div className="flex items-center space-x-4">
            <a
              href="#"
              className="text-sm text-gray-500 hover:text-gray-900 transition-colors"
            >
              이용약관
            </a>
            <a
              href="#"
              className="text-sm text-gray-500 hover:text-gray-900 transition-colors"
            >
              개인정보처리방침
            </a>
            <a
              href="#"
              className="text-sm text-gray-500 hover:text-gray-900 transition-colors"
            >
              고객센터
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
