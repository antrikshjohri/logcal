const faq = [
  {
    question: "How accurate is the calorie estimation?",
    answer:
      "LogCal uses OpenAI's GPT-4 to analyze your meal descriptions and provide calorie estimates. While highly accurate, estimates may vary based on portion sizes and preparation methods. We recommend being as specific as possible in your descriptions."
  },
  {
    question: "Can I edit logged meals?",
    answer:
      "Yes! Navigate to the History screen, find the meal you want to edit, and tap on it to view details. You can then adjust the calorie count or delete the entry."
  },
  {
    question: "How do I change my daily calorie goal?",
    answer:
      "Go to Profile > Daily Goal, then use the slider to adjust your daily calorie target. Your new goal will be saved automatically and synced across all your devices."
  },
  {
    question: "Does LogCal work offline?",
    answer:
      "LogCal requires an internet connection to analyze meals using AI. However, you can view your previously logged meals offline."
  },
  {
    question: "Is my data private and secure?",
    answer:
      "Absolutely. We use industry-standard encryption to protect your data. Your meal logs and personal information are never shared with third parties. See our Privacy Policy for more details."
  },
  {
    question: "How does the voice input work?",
    answer:
      "Tap the microphone icon when logging a meal to use voice input. Your device will convert speech to text, which is then analyzed by our AI to estimate calories."
  },
  {
    question: "What if the calorie estimate seems wrong?",
    answer:
      'You can manually adjust any calorie estimate after logging. We also recommend providing detailed descriptions (e.g., "grilled chicken breast, 6 oz" instead of just "chicken").'
  },
  {
    question: "How do I sync my data across devices?",
    answer:
      "Simply sign in with the same Google or Apple account on all your devices. Your meal logs and daily goal will automatically sync via secure cloud storage."
  }
];

export const metadata = {
  title: "Support"
};

export default function SupportPage() {
  return (
    <div className="site-shell inner-page support-page">
      <article className="support-card">
        <header className="support-header">
          <h1>LogCal Support</h1>
          <p>We're here to help you get the most out of LogCal</p>
        </header>

        <section className="support-section">
          <h2>Get Help</h2>
          <p>
            Need assistance with LogCal? We're here to help! Check out our
            frequently asked questions below, or contact us directly.
          </p>

          <div className="support-contact-card">
            <h3>Contact Us</h3>
            <p>
              <strong>Email:</strong>{" "}
              <a href="mailto:johriantriksh24@gmail.com">
                johriantriksh24@gmail.com
              </a>
            </p>
            <p>We typically respond within 24-48 hours.</p>
          </div>
        </section>

        <section className="support-section">
          <h2>Frequently Asked Questions</h2>
          <div className="support-faq-list">
            {faq.map((item) => (
              <article className="support-faq-item" key={item.question}>
                <h3>{item.question}</h3>
                <p>{item.answer}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="support-section">
          <h2>Privacy &amp; Terms</h2>
          <p>
            Your privacy is important to us. Learn more about how we protect
            your data:
          </p>
          <a className="support-button" href="/privacy/">
            View Privacy Policy
          </a>
        </section>

        <section className="support-section">
          <h2>Report an Issue</h2>
          <p>
            Found a bug or experiencing an issue? Please email us at{" "}
            <a href="mailto:johriantriksh24@gmail.com">
              johriantriksh24@gmail.com
            </a>{" "}
            with:
          </p>
          <ul>
            <li>Description of the issue</li>
            <li>Steps to reproduce (if applicable)</li>
            <li>Device model and iOS version</li>
            <li>Screenshots (if helpful)</li>
          </ul>
        </section>

        <section className="support-section">
          <h2>Feature Requests</h2>
          <p>
            Have an idea for improving LogCal? We'd love to hear from you! Send
            your suggestions to{" "}
            <a href="mailto:johriantriksh24@gmail.com">
              johriantriksh24@gmail.com
            </a>
            .
          </p>
        </section>
      </article>
    </div>
  );
}
