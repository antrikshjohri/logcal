import Image from "next/image";

const proofPoints = [
  {
    label: "Voice, text, or photo",
    icon: "/icons/mic.png"
  },
  {
    label: "AI calorie estimates",
    icon: "/icons/ai-sparkle.webp"
  },
  {
    label: "Built for health",
    icon: "/icons/health.png"
  }
];

const howItWorks = [
  {
    title: "Speak it",
    imageSrc: "/how-it-works/speak-it.png",
    imageWidth: 857,
    imageHeight: 1143
  },
  {
    title: "Snap it",
    imageSrc: "/how-it-works/snap-it.png",
    imageWidth: 857,
    imageHeight: 1143
  },
  {
    title: "Track it",
    imageSrc: "/how-it-works/track-it.png",
    imageWidth: 857,
    imageHeight: 1143
  }
];

const features = [
  {
    title: "AI Meal Logging",
    body: "Describe or snap your meal instantly.",
    icon: "spark"
  },
  {
    title: "Voice Food Logging",
    body: "Log meals hands-free in any language.",
    icon: "mic"
  },
  {
    title: "Photo-Based Estimates",
    body: "Snap your meal. Get instant calorie insights.",
    icon: "camera"
  },
  {
    title: "Daily Calorie Dashboard",
    body: "See your progress and stay on track.",
    icon: "chart"
  },
  {
    title: "Meal History",
    body: "Review your meals anytime, anywhere.",
    icon: "history"
  },
  {
    title: "Streaks & Consistency",
    body: "Build streaks and stay consistent.",
    icon: "flame"
  }
];

const benefits = [
  {
    title: "Spend less time logging",
    body: "Log meals in seconds, not minutes.",
    icon: "clock"
  },
  {
    title: "Build consistency without stress",
    body: "Simple is easy to stick with.",
    icon: "target"
  },
  {
    title: "Understand calories, not obsess over them",
    body: "Get clear insight without guilt.",
    icon: "heart"
  },
  {
    title: "Works for real meals and messy plates",
    body: "No need for perfect meals or perfect days.",
    icon: "utensils"
  },
  {
    title: "Stay mindful on busy days",
    body: "Track what matters, even when life's busy.",
    icon: "leaf"
  }
];

const testimonials = [
  {
    quote:
      "LogCalAI makes tracking food so easy that I actually lost weight without overthinking.",
    name: "Neha S.",
    role: "Busy Professional"
  },
  {
    quote:
      "Logging takes literally 10 seconds. I just speak and boom. Super convenient.",
    name: "Rahul M.",
    role: "Fitness Enthusiast"
  },
  {
    quote:
      "Finally, an app that understands real food. The photo logging feels incredibly useful.",
    name: "Priya K.",
    role: "Health Coach"
  }
];

function Icon({ name }: { name: string }) {
  return <span className={`icon icon-${name}`} aria-hidden="true" />;
}

function ProofIcon({
  src,
  alt,
  className = ""
}: {
  src: string;
  alt: string;
  className?: string;
}) {
  return (
    <Image
      src={src}
      alt={alt}
      width={28}
      height={28}
      className={`proof-asset-icon ${className}`}
    />
  );
}

function LeafMark() {
  return (
    <span className="leaf-mark" aria-hidden="true">
      <span />
      <span />
      <span />
    </span>
  );
}

function DownloadButton({ className = "" }: { className?: string }) {
  return (
    // Replace "#" with the real store URL once the listing is live.
    <a className={`download-button ${className}`} href="#">
      <ProofIcon
        src="/icons/mobile.png"
        alt=""
        className="proof-asset-icon-mobile"
      />
      <span>Download the app</span>
    </a>
  );
}

function StoreBadge({ store }: { store: "apple" | "google" }) {
  return (
    // Replace "#" with the real store URL once available.
    <a className="store-badge" href="#">
      <span className="store-icon" aria-hidden="true">
        {store === "apple" ? "a" : "p"}
      </span>
      <span>
        <small>{store === "apple" ? "Download on the" : "GET IT ON"}</small>
        <strong>{store === "apple" ? "App Store" : "Google Play"}</strong>
      </span>
    </a>
  );
}

function PhoneMockup({ tilted = false }: { tilted?: boolean }) {
  return (
    <div className={`phone-shell ${tilted ? "phone-tilted" : ""}`}>
      <div className="phone-frame">
        <div className="phone-notch" />
        <div className="phone-screen">
          <div className="phone-status">
            <span>9:41</span>
            <span className="status-icons" />
          </div>
          <div className="phone-date">
            <strong>Today</strong>
            <span>May 20</span>
          </div>
          <div className="progress-ring">
            <span>1,340</span>
            <small>/ 2,000 kcal</small>
            <em>67% of goal</em>
          </div>
          <div className="macro-strip">
            <span>
              Protein <strong>92g</strong>
            </span>
            <span>
              Carbs <strong>165g</strong>
            </span>
            <span>
              Fat <strong>46g</strong>
            </span>
          </div>
          <div className="recent-meal">
            <span className="meal-thumb" />
            <span>
              <strong>Grilled Chicken Bowl</strong>
              <small>520 kcal</small>
            </span>
          </div>
          <div className="phone-tabs">
            <span className="active" />
            <span />
            <span />
            <span />
            <span />
          </div>
        </div>
      </div>
    </div>
  );
}

function HeroPhoneMockup() {
  return (
    <div className="hero-phone-shell hero-phone-image-shell">
      {/* Replace this file if you export a newer hero screenshot from the app. */}
      <Image
        src="/hero/voice-meal-logging.png"
        alt="LogCal voice meal logging screen"
        width={1254}
        height={1254}
        className="hero-phone-image"
        priority
      />
    </div>
  );
}

function MiniMealPhoto() {
  return (
    <div className="mini-meal-photo" aria-hidden="true">
      <span className="bowl" />
      <span className="rice" />
      <span className="greens" />
      <span className="tomatoes" />
    </div>
  );
}

function SandwichPlate() {
  return (
    <div className="sandwich-plate" aria-hidden="true">
      <span className="sandwich-plate-base" />
      <span className="sandwich-bread sandwich-top" />
      <span className="sandwich-filling sandwich-lettuce" />
      <span className="sandwich-filling sandwich-tomato" />
      <span className="sandwich-filling sandwich-avocado" />
      <span className="sandwich-bread sandwich-bottom" />
      <span className="apple-slice slice-one" />
      <span className="apple-slice slice-two" />
      <span className="apple-slice slice-three" />
    </div>
  );
}

function HeroVoiceCard() {
  return (
    <div className="hero-side-card voice-log-card">
      <div className="voice-log-header">
        <span className="voice-log-pill">
          <ProofIcon src="/icons/mic.png" alt="" />
        </span>
        <strong>Voice log</strong>
      </div>
      <p>
        &ldquo;I had a turkey sandwich on sourdough with avocado and a side of
        apple.&rdquo;
      </p>
      <div className="voice-wave">
        <i />
        <i />
        <i />
        <i />
        <i />
        <i />
        <i />
        <i />
        <i />
        <i />
        <i />
        <i />
        <i />
      </div>
      <button className="voice-mic-button" type="button" aria-label="Voice log">
        <ProofIcon src="/icons/mic.png" alt="" />
      </button>
      <span className="voice-listening">Listening...</span>
    </div>
  );
}

function HeroMealCard() {
  return (
    <div className="hero-side-card meal-card">
      <span className="meal-badge">Meal recognized</span>
      <SandwichPlate />
      <strong className="meal-card-title">
        Turkey sandwich with avocado and an apple
      </strong>
      <span className="meal-card-calories">520 kcal</span>
      <div className="meal-card-macros">
        <span>Protein 28g</span>
        <span>Carbs 45g</span>
        <span>Fat 18g</span>
      </div>
    </div>
  );
}

function AvatarStack() {
  return (
    <div className="avatar-stack" aria-hidden="true">
      <span className="avatar avatar-1" />
      <span className="avatar avatar-2" />
      <span className="avatar avatar-3" />
      <span className="avatar avatar-4" />
    </div>
  );
}

export default function HomePage() {
  return (
    <div className="homepage">
      <section className="design-panel hero-panel">
        <div className="hero-copy">
          <h1>Log meals in seconds with AI</h1>
          <p>
            Tell LogCal what you ate. It estimates calories and keeps your day
            on track.
          </p>
          <div className="hero-actions">
            <DownloadButton />
            <a className="secondary-button" href="#how-it-works">
              <span>See how it works</span>
              <span className="arrow-mark" aria-hidden="true" />
            </a>
          </div>
          <div className="proof-row">
            {proofPoints.map((point) => (
              <span key={point.label}>
                <ProofIcon src={point.icon} alt="" />
                {point.label}
              </span>
            ))}
          </div>
        </div>

        <div className="hero-visual">
          <HeroPhoneMockup />
          <div className="hero-side-stack">
            <HeroVoiceCard />
            <HeroMealCard />
          </div>
        </div>
      </section>

      <section id="how-it-works" className="design-panel how-panel">
        <div className="section-heading centered">
          <h2>Three simple ways to log any meal</h2>
          <p>LogCalAI makes calorie tracking effortless.</p>
        </div>
        <div className="steps-layout">
          {howItWorks.map((step, index) => (
            <article className="step-block" key={step.title}>
              <span className="number-circle">{index + 1}</span>
              <div className="step-image-card">
                <Image
                  src={step.imageSrc}
                  alt={step.title}
                  width={step.imageWidth}
                  height={step.imageHeight}
                  className="step-image"
                />
              </div>
              {index < howItWorks.length - 1 && (
                <span className="dotted-arrow" aria-hidden="true" />
              )}
            </article>
          ))}
        </div>
      </section>

      <section id="features" className="design-panel features-panel">
        <div className="section-copy-block">
          <h2>Everything you need to track smarter</h2>
          <p>Powerful features that make healthy habits stick.</p>
        </div>
        <div className="feature-grid">
          {features.map((feature) => (
            <article className="feature-card" key={feature.title}>
              <Icon name={feature.icon} />
              <h3>{feature.title}</h3>
              <p>{feature.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section id="benefits" className="design-panel benefits-panel">
        <div className="section-copy-block benefit-copy">
          <h2>Why LogCalAI makes tracking easier</h2>
          <p>
            We built LogCalAI for real life. No rigid rules. No complicated
            processes. Just effortless tracking that fits your day.
          </p>
          <div className="leaf-cluster" aria-hidden="true">
            <span />
            <span />
            <span />
          </div>
        </div>
        <div className="benefit-list">
          {benefits.map((benefit) => (
            <article className="benefit-card" key={benefit.title}>
              <Icon name={benefit.icon} />
              <div>
                <h3>{benefit.title}</h3>
                <p>{benefit.body}</p>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section id="testimonials" className="design-panel testimonials-panel">
        <div className="section-copy-block">
          <h2>Loved by people who want simplicity</h2>
          <p>Real people. Real results.</p>
        </div>
        <div className="testimonial-grid">
          {testimonials.map((testimonial, index) => (
            <article className="testimonial-card" key={testimonial.name}>
              <div className="stars" aria-label="5 star rating">
                *****
              </div>
              <blockquote>"{testimonial.quote}"</blockquote>
              <div className="testimonial-person">
                <span className={`avatar avatar-${index + 1}`} />
                <div>
                  <strong>{testimonial.name}</strong>
                  <span>{testimonial.role}</span>
                </div>
              </div>
            </article>
          ))}
        </div>
        <div className="social-proof">
          <AvatarStack />
          <span>Join thousands of happy users</span>
          <strong>4.8</strong>
          <span className="stars">*****</span>
          <span>(2.1K+ ratings)</span>
        </div>
      </section>

      <section className="design-panel final-panel">
        <div className="final-copy">
          <h2>Start tracking smarter today.</h2>
          <p>Your next meal can be logged in seconds.</p>
          <div className="hero-actions">
            <DownloadButton />
            <a className="secondary-button" href="#how-it-works">
              <span>See how it works</span>
              <span className="arrow-mark" aria-hidden="true" />
            </a>
          </div>
          <div className="availability-row">
            <span>Available on iOS</span>
            <i />
            <span>Coming soon to Android</span>
          </div>
        </div>
        <div className="final-visual">
          <div className="final-leaves" aria-hidden="true">
            <span />
            <span />
            <span />
            <span />
          </div>
          <PhoneMockup tilted />
        </div>
      </section>

      <footer className="footer-panel">
        <div className="footer-brand">
          <a className="footer-logo" href="/">
            <LeafMark />
            <span>LogCalAI</span>
          </a>
          <p>AI calorie tracking that fits your life. Speak it. Snap it. Track it.</p>
          <div className="store-row">
            <StoreBadge store="apple" />
            <StoreBadge store="google" />
          </div>
          <div className="social-icons">
            <a href="#" aria-label="Instagram">ig</a>
            <a href="#" aria-label="Facebook">f</a>
            <a href="#" aria-label="LinkedIn">in</a>
          </div>
        </div>

        <nav className="footer-column" aria-label="Product">
          <h3>Product</h3>
          <a href="#features">Features</a>
          <a href="#how-it-works">How it works</a>
          <a href="#testimonials">Testimonials</a>
          <a href="/app/">About</a>
        </nav>

        <nav className="footer-column" aria-label="Support">
          <h3>Support</h3>
          <a href="/support/">Help Center</a>
          <a href="mailto:johriantriksh24@gmail.com">Contact Us</a>
          <a href="/privacy/">Privacy Policy</a>
          <a href="/terms/">Terms of Use</a>
        </nav>

        <div className="footer-column newsletter">
          <h3>Stay updated</h3>
          <p>Get tips, updates, and health insights.</p>
          <form className="email-form">
            <label htmlFor="email">Email address</label>
            <input id="email" type="email" placeholder="Enter your email" />
            <button type="submit" aria-label="Subscribe">
              <span className="arrow-mark" aria-hidden="true" />
            </button>
          </form>
        </div>

        <div className="footer-bottom">
          <span>&copy; 2026 LogCalAI. All rights reserved.</span>
        </div>
      </footer>
    </div>
  );
}
