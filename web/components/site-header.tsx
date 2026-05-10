import Image from "next/image";

const navItems = [
  { href: "/#features", label: "Features" },
  { href: "/#how-it-works", label: "How it works" },
  { href: "/#testimonials", label: "Testimonials" },
  { href: "/app/", label: "About" }
];

export function SiteHeader() {
  return (
    <header className="site-shell">
      <div className="topbar">
        <a className="brand" href="/">
          <span className="brand-mark">
            <Image
              src="/images/logcal-app-icon.png"
              alt=""
              width={64}
              height={64}
              className="brand-mark-image"
            />
          </span>
          <span>LogCalAI</span>
        </a>

        <nav className="nav" aria-label="Primary">
          {navItems.map((item) => (
            <a key={item.href} href={item.href}>
              {item.label}
            </a>
          ))}
        </nav>

        <div className="topbar-cta">
          <a className="header-download" href="#">
            Download the app
          </a>
        </div>
      </div>
    </header>
  );
}
