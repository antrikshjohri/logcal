import { SUPPORT_EMAIL } from "../lib/site";
import { StoreLink } from "./store-link";

const footerLinks = [
  { href: "/features/", label: "Features" },
  { href: "/support/", label: "Support" },
  { href: "/privacy/", label: "Privacy" },
  { href: "/terms/", label: "Terms" }
];

export function SiteFooter() {
  return (
    <footer className="site-shell footer">
      <div className="footer-grid">
        <div>
          <p className="eyebrow">LogCalAI</p>
          <p className="footer-copy">
            Fast calorie tracking for people who want less friction and better
            consistency.
          </p>
        </div>

        <div className="footer-links">
          {footerLinks.map((item) => (
            <a key={item.href} href={item.href}>
              {item.label}
            </a>
          ))}
        </div>

        <div>
          <p className="footer-heading">Download</p>
          <StoreLink className="store-badge footer-store-badge" />
        </div>

        <div>
          <p className="footer-heading">Contact</p>
          <a className="footer-link" href={`mailto:${SUPPORT_EMAIL}`}>
            {SUPPORT_EMAIL}
          </a>
        </div>
      </div>
    </footer>
  );
}
