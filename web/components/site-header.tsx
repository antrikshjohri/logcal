"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";

import { StoreBadgeGroup } from "./store-link";

const navItems = [
  { href: "/", label: "Home" },
  { href: "/#features", label: "Features" },
  { href: "/#how-it-works", label: "How it works" },
  { href: "/blog/", label: "Blog" },
  { href: "/#testimonials", label: "Testimonials" }
];

export function SiteHeader() {
  const [isDownloadOpen, setIsDownloadOpen] = useState(false);
  const downloadMenuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!isDownloadOpen) {
      return;
    }

    function closeOnOutsideClick(event: MouseEvent) {
      if (
        downloadMenuRef.current &&
        !downloadMenuRef.current.contains(event.target as Node)
      ) {
        setIsDownloadOpen(false);
      }
    }

    function closeOnEscape(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setIsDownloadOpen(false);
      }
    }

    document.addEventListener("mousedown", closeOnOutsideClick);
    document.addEventListener("keydown", closeOnEscape);

    return () => {
      document.removeEventListener("mousedown", closeOnOutsideClick);
      document.removeEventListener("keydown", closeOnEscape);
    };
  }, [isDownloadOpen]);

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
          </nav>
        </details>

        <div className="topbar-cta">
          <div className="topbar-download-menu" ref={downloadMenuRef}>
            <button
              className="header-download"
              type="button"
              aria-expanded={isDownloadOpen}
              aria-controls="header-download-panel"
              onClick={() => setIsDownloadOpen((isOpen) => !isOpen)}
            >
              Download
            </button>
            {isDownloadOpen && (
              <div
                className="topbar-download-panel"
                id="header-download-panel"
              >
                <StoreBadgeGroup
                  className="store-row header-store-row"
                  onClick={() => setIsDownloadOpen(false)}
                />
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
}
