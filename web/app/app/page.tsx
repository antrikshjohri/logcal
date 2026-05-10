const roadmap = [
  "Authenticated meal history across devices",
  "A browser-based logging surface for quick desktop use",
  "Shared Firebase-backed identity and sync with the iPhone app"
];

export const metadata = {
  title: "Web App"
};

export default function FutureAppPage() {
  return (
    <div className="site-shell inner-page">
      <section className="page-hero card accent-card">
        <p className="eyebrow">Future web app</p>
        <h1>The LogCal web experience is being staged intentionally.</h1>
        <p className="page-copy">
          Today, this route acts as a product bridge. Later, it can become the
          authenticated experience behind <code>app.logcalai.com</code>.
        </p>
      </section>

      <section className="two-column">
        <div className="card">
          <h2>What is ready now</h2>
          <p className="section-copy">
            The repository now has a dedicated web codebase, deployable on
            Firebase Hosting, with a route structure that cleanly separates
            marketing pages from future product pages.
          </p>
        </div>

        <div className="card">
          <h2>Planned web app capabilities</h2>
          <ul className="plain-list">
            {roadmap.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </div>
      </section>
    </div>
  );
}
