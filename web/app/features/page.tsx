const features = [
  {
    title: "Text, voice, and photo logging",
    body:
      "Capture meals the way they naturally happen. LogCal is built for typed descriptions, spoken notes, and image-assisted input."
  },
  {
    title: "AI-generated meal structure",
    body:
      "Instead of a raw calorie guess, the system is designed to return structured details you can review and refine."
  },
  {
    title: "Cloud sync and identity",
    body:
      "Firebase Auth and Firestore power user identity, meal sync, and settings so the experience can extend across devices over time."
  },
  {
    title: "Fast daily review",
    body:
      "The product direction emphasizes simple summaries, history, and helpful reminders over obsessive complexity."
  }
];

export const metadata = {
  title: "Features"
};

export default function FeaturesPage() {
  return (
    <div className="site-shell inner-page">
      <section className="page-hero card">
        <p className="eyebrow">Features</p>
        <h1>Built to make logging feel easier, not heavier.</h1>
        <p className="page-copy">
          LogCal combines AI-assisted meal understanding with a calmer product
          experience so tracking can fit real routines instead of idealized
          ones.
        </p>
      </section>

      <section className="feature-grid">
        {features.map((feature) => (
          <article key={feature.title} className="feature-card">
            <h2>{feature.title}</h2>
            <p>{feature.body}</p>
          </article>
        ))}
      </section>
    </div>
  );
}
