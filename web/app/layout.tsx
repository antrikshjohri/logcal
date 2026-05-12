import type { Metadata } from "next";
import { Manrope } from "next/font/google";

import { SiteHeader } from "../components/site-header";
import "./globals.css";

const appFont = Manrope({
  subsets: ["latin"],
  variable: "--font-body"
});

export const metadata: Metadata = {
  metadataBase: new URL("https://logcalai.com"),
  title: {
    default: "LogCal: AI Calorie Tracker",
    template: "%s | LogCal: AI Calorie Tracker"
  },
  description:
    "The least-effort way to track calories and macros. Speak, type, or snap your meal and get instant AI-powered estimates.",
  icons: {
    icon: [
      {
        url: "/favicon.png",
        type: "image/png",
        sizes: "48x48"
      }
    ],
    apple: [
      {
        url: "/apple-touch-icon.png",
        type: "image/png",
        sizes: "180x180"
      }
    ]
  },
  openGraph: {
    title: "LogCal: AI Calorie Tracker",
    description:
      "The least-effort way to track calories and macros. Speak, type, or snap your meal and get instant AI-powered estimates.",
    url: "https://logcalai.com",
    siteName: "LogCal: AI Calorie Tracker",
    type: "website"
  }
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={appFont.variable}>
        <div className="page-chrome">
          <SiteHeader />
          <main>{children}</main>
        </div>
      </body>
    </html>
  );
}
