import { readFileSync } from "node:fs";
import { join } from "node:path";

export const metadata = {
  title: "Privacy Policy"
};

const privacyPolicyHtml = readFileSync(
  join(process.cwd(), "public/legal/privacypolicy.html"),
  "utf8"
);

export default function PrivacyPage() {
  return (
    <div className="site-shell inner-page privacy-policy-page">
      <article
        className="privacy-policy-card"
        dangerouslySetInnerHTML={{ __html: privacyPolicyHtml }}
      />
    </div>
  );
}
