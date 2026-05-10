const faq = [
  {
    question: "How accurate are the calorie estimates?",
    answer:
      "They are intended to be fast, useful estimates. More detail in your description usually improves the result, and the experience is designed so you can review and adjust entries."
  },
  {
    question: "How does sync work?",
    answer:
      "When you sign in with the same account, LogCal can sync meals and settings through Firebase-backed cloud storage."
  },
  {
    question: "How should I report a bug?",
    answer:
      "Send a short description, steps to reproduce, your device model, iOS version, and screenshots if they help."
  }
];

export const metadata = {
  title: "Support"
};

export default function SupportPage() {
  return (
    <div className="site-shell inner-page">
      <section className="page-hero card">
        <p className="eyebrow">Support</p>
        <h1>Help for the current LogCal experience.</h1>
        <p className="page-copy">
          If you need help, found a bug, or want to suggest a feature, the
          fastest path is email.
        </p>
        <div className="cta-row">
          <a
            className="button button-primary"
            href="mailto:johriantriksh24@gmail.com"
          >
            Email support
          </a>
          <a className="button button-secondary" href="/legal/support-legacy.html">
            View legacy support page
          </a>
        </div>
      </section>

      <section className="two-column support-grid">
        <div className="card">
          <h2>What to include in support requests</h2>
          <ul className="plain-list">
            <li>A short description of the issue</li>
            <li>Steps to reproduce it if possible</li>
            <li>Your device model and iOS version</li>
            <li>Screenshots when they make the issue clearer</li>
          </ul>
        </div>

        <div className="card">
          <h2>Frequently asked questions</h2>
          <div className="faq-list">
            {faq.map((item) => (
              <article key={item.question} className="faq-card">
                <h3>{item.question}</h3>
                <p>{item.answer}</p>
              </article>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}
