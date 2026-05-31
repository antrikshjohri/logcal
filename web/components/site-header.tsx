"use client";

import Image from "next/image";
import { usePathname } from "next/navigation";

const navItems = [
  { href: "/", label: "Home" },
  { href: "/#features", label: "Features" },
  { href: "/#how-it-works", label: "How it works" },
  { href: "/blog/", label: "Blog" },
  { href: "/#testimonials", label: "Testimonials" }
];

const appStoreUrl =
  "https://apps.apple.com/us/app/logcal-ai-calorie-tracker/id6757228315";

export function SiteHeader() {
  const pathname = usePathname();

  // Hide the landing page header inside the web app dashboard
  if (pathname && pathname.startsWith("/app/")) {
    return null;
  }

  return (
    <header className="site-shell">
      <div className="topbar">
        <a className="brand" href="/">
          <span className="brand-mark">
            <Image
              src="/images/logcal-transparent-logo-64.webp"
              alt=""
              width={64}
              height={64}
              className="brand-mark-image"
            />
          </span>
          <span>LogCal AI</span>
        </a>

        <nav className="nav" aria-label="Primary">
          {navItems.map((item) => (
            <a key={item.href} href={item.href}>
              {item.label}
            </a>
          ))}
        </nav>

        <details className="mobile-menu">
          <summary aria-label="Open navigation menu">
            <span />
            <span />
            <span />
          </summary>
          <nav className="mobile-menu-panel" aria-label="Mobile">
            {navItems.map((item) => (
              <a key={item.href} href={item.href}>
                {item.label}
              </a>
            ))}
            <a href="/app/" style={{ color: "var(--green)", fontWeight: 900 }}>
              Launch Web App
            </a>
          </nav>
        </details>

        <div className="topbar-cta" style={{ display: "flex", gap: "12px", alignItems: "center" }}>
          <a
            className="secondary-button"
            href="/app/"
            style={{ minHeight: "52px", padding: "0 24px", fontSize: "15px" }}
          >
            Launch Web App
          </a>
          <a
            className="header-download"
            href={appStoreUrl}
            target="_blank"
            rel="noreferrer"
            style={{ display: "inline-flex", alignItems: "center" }}
          >
            Download the app
          </a>
        </div>
      </div>
    </header>
  );
}
