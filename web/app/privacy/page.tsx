export const metadata = {
  title: "Privacy"
};

export default function PrivacyPage() {
  return (
    <div className="site-shell inner-page">
      <section className="page-hero card">
        <p className="eyebrow">Privacy</p>
        <h1>Your privacy matters to LogCal.</h1>
        <p className="page-copy">
          This site preserves your existing privacy-policy document while also
          giving the main website a cleaner summary page.
        </p>
        <div className="cta-row">
          <a className="button button-primary" href="/legal/privacypolicy.html">
            Read the full privacy policy
          </a>
          <a
            className="button button-secondary"
            href="mailto:johriantriksh24@gmail.com"
          >
            Privacy questions
          </a>
        </div>
      </section>

      <section className="two-column">
        <div className="card">
          <h2>What this page is for</h2>
          <p className="section-copy">
            The marketing site gives visitors a clean place to find privacy and
            support information without losing the existing legal document you
            already use.
          </p>
        </div>

        <div className="card">
          <h2>Need the exact legal text?</h2>
          <p className="section-copy">
            Use the full policy link above. It points to the preserved HTML
            policy document that now ships with the website.
          </p>
        </div>
      </section>
    </div>
  );
}
