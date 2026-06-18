import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
  display: "swap",
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
  display: "swap",
});

const ICP_BEIAN_NO = "ICP备案/许可证号：";
const GONGAN_BEIAN_NO = "晋ICP备2026005636号";

export const metadata: Metadata = {
  title: {
    default: "XiaoYu's Home",
    template: "%s | XiaoYu's Home",
  },
  description: "XiaoYu's personal homepage — developer, creator, and lifelong learner.",
  keywords: ["XiaoYu", "personal homepage", "developer", "portfolio"],
  authors: [{ name: "XiaoYu" }],
  openGraph: {
    title: "XiaoYu's Home",
    description: "Developer, creator, and lifelong learner.",
    type: "website",
    locale: "zh_CN",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#f5f5f7",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="zh-CN"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
      </head>
      <body className="min-h-full flex flex-col bg-[#f5f5f7] text-slate-900">
        {children}
        <footer className="flex flex-wrap items-center justify-center gap-x-4 gap-y-1 px-4 py-6 text-[11px] text-slate-400/70">
          <a
            href="https://beian.miit.gov.cn/"
            target="_blank"
            rel="noreferrer"
            className="transition hover:text-slate-600"
          >
            {ICP_BEIAN_NO}
          </a>
          <a
            href="https://beian.mps.gov.cn/"
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-1 transition hover:text-slate-600"
          >
            <img src="/beian/gongan.png" alt="" className="h-3.5 w-3.5" />
            <span>{GONGAN_BEIAN_NO}</span>
          </a>
        </footer>
      </body>
    </html>
  );
}