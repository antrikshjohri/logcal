import Image from "next/image";

import { FeatureCard } from "../components/feature-card";
import { FiveStarRating } from "../components/star-rating";

const proofPoints = [
  {
    label: "Voice, text, or photo",
    icon: "/icons/mic.webp"
  },
  {
    label: "AI calorie estimates",
    icon: "/icons/ai-sparkle.webp"
  },
  {
    label: "Built for health",
    icon: "/icons/health.webp"
  }
];

const howItWorks = [
  {
    title: "Speak it",
    imageSrc: "/how-it-works/speak-it.webp",
    imageWidth: 520,
    imageHeight: 694
  },
  {
    title: "Snap it",
    imageSrc: "/how-it-works/snap-it.webp",
    imageWidth: 520,
    imageHeight: 694
  },
  {
    title: "Track it",
    imageSrc: "/how-it-works/track-it.webp",
    imageWidth: 520,
    imageHeight: 694
  }
];

const features = [
  {
    icon: "spark",
    title: "AI Meal Logging",
    description: "Describe or snap your meal instantly."
  },
  {
    icon: "mic",
    title: "Voice Food Logging",
    description: "Log meals hands-free in any language."
  },
  {
    icon: "camera",
    title: "Photo-Based Estimates",
    description: "Snap your meal. Get instant calorie insights."
  },
  {
    icon: "chart",
    title: "Daily Calorie Dashboard",
    description: "See your progress and stay on track."
  },
  {
    icon: "history",
    title: "Meal History",
    description: "Review your meals anytime, anywhere."
  },
  {
    icon: "flame",
    title: "Streaks & Consistency",
    description: "Build streaks and stay consistent."
  }
] as const;

const testimonials = [
  {
    quote:
      "Very easy to use. I always had difficulty in tracking my calories but its so easy with this app. Just have to speak it out. Love it!",
    name: "Jahnvi S.",
    role: "Fitness Enthusiast",
    initials: "JS"
  },
  {
    quote:
      "Finally able to track calories for Indian food! Loving the fact that AI meets food tracking. Definitely give it a shot.",
    name: "Paaras S.",
    role: "Entrepreneur",
    initials: "PS"
  },
  {
    quote:
      "Logging takes literally 10 seconds. I just speak and boom. Super convenient.",
    name: "Aakash J.",
    role: "MBA graduate",
    initials: "AJ"
  }
] as const;

const appStoreUrl =
  "https://apps.apple.com/us/app/logcal-ai-calorie-tracker/id6757228315";

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

function DownloadButton({ className = "" }: { className?: string }) {
  return (
    <a
      className={`download-button ${className}`}
      href={appStoreUrl}
      target="_blank"
      rel="noreferrer"
    >
      <ProofIcon
        src="/icons/mobile.webp"
        alt=""
        className="proof-asset-icon-mobile"
      />
      <span>Download the app</span>
    </a>
  );
}

function StoreBadge() {
  return (
    <a
      className="store-badge"
      href={appStoreUrl}
      aria-label="Download LogCalAI on the App Store"
      target="_blank"
      rel="noreferrer"
    >
      <img
        src="/badges/app-store-badge.svg"
        alt="Download on the App Store"
        width={140}
        height={42}
      />
    </a>
  );
}

function HeroPhoneMockup() {
  return (
    <div className="hero-phone-shell hero-phone-image-shell">
      {/* Replace this file if you export a newer hero screenshot from the app. */}
      <picture>
        <source
          media="(max-width: 900px)"
          srcSet="/hero/voice-meal-logging-520.webp"
        />
        <source
          media="(max-width: 1180px)"
          srcSet="/hero/voice-meal-logging-720.webp"
        />
        <img
          src="/hero/voice-meal-logging.webp"
          alt="LogCal voice meal logging screen"
          width={1254}
          height={1254}
          className="hero-phone-image"
          fetchPriority="high"
          decoding="async"
        />
      </picture>
    </div>
  );
}

function FinalDashboardMockup() {
  return (
    <div className="final-dashboard-shell">
      <Image
        src="/final-cta/dashboard-home-view.webp"
        alt="LogCal dashboard showing daily calories, macros, and weekly trends"
        width={360}
        height={738}
        className="final-dashboard-image"
        sizes="(max-width: 560px) 210px, (max-width: 900px) 250px, 360px"
      />
    </div>
  );
}

function HeroVoiceCard() {
  return (
    <div className="hero-side-card voice-log-card">
      <div className="voice-log-header">
        <span className="voice-log-pill">
          <ProofIcon src="/icons/mic.webp" alt="" />
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
        <ProofIcon src="/icons/mic.webp" alt="" />
      </button>
      <span className="voice-listening">Listening...</span>
    </div>
  );
}

function HeroMealCard() {
  return (
    <div className="hero-side-card meal-card">
      <span className="meal-badge">Meal recognized</span>
      <span className="meal-card-image-frame">
        <Image
          src="/hero/sourdough-sandwich-144.webp"
          alt="Turkey sandwich with avocado and apple slices"
          width={144}
          height={144}
          className="meal-card-image"
        />
      </span>
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

export default function HomePage() {
  return (
    <div className="homepage">
      <section className="design-panel hero-panel">
        <div className="hero-copy">
          <h1>Log meals in seconds with AI</h1>
          <p>
          Track calories effortlessly. Speak, type, or snap your meal — LogCal estimates it in seconds. 
          </p>
          <div className="hero-actions">
            <DownloadButton />
            <a className="secondary-button" href="/app/">
              <span>Try now for free</span>
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
          <h2>How it works</h2>
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
                  sizes="(max-width: 900px) 78vw, 33vw"
                />
              </div>
              {index < howItWorks.length - 1 && (
                <span className="dotted-arrow" aria-hidden="true" />
              )}
            </article>
          ))}
        </div>
      </section>

      <section className="blog-promo-band" aria-label="LogCal AI blog">
        <div>
          <span className="eyebrow">From the blog</span>
          <h2>Practical guides for easier calorie tracking</h2>
        </div>
        <p>
          Explore portions, photo logging, weight-loss consistency, and small
          habits, plus simple macro guides for protein, carbs, and fats.
        </p>
        <a href="/blog/">Browse all posts</a>
      </section>

      <section id="features" className="design-panel features-panel">
        <div className="section-copy-block">
          <h2>Everything you need to track smarter</h2>
          <p>Powerful features that make healthy habits stick.</p>
        </div>
        <div className="feature-grid">
          {features.map((feature) => (
            <FeatureCard
              key={feature.title}
              icon={feature.icon}
              title={feature.title}
              description={feature.description}
            />
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
              <FiveStarRating />
              <figure className="testimonial-figure">
                <blockquote>
                  <p>&ldquo;{testimonial.quote}&rdquo;</p>
                </blockquote>
                <figcaption className="testimonial-person">
                  <span
                    className={`avatar avatar-${index + 1}`}
                    aria-hidden="true"
                  >
                    {testimonial.initials}
                  </span>
                  <div>
                    <strong>{testimonial.name}</strong>
                    <span>{testimonial.role}</span>
                  </div>
                </figcaption>
              </figure>
            </article>
          ))}
        </div>
      </section>

      <section className="design-panel final-panel">
        <div className="final-copy">
          <h2>Start tracking smarter today.</h2>
          <p>Your next meal can be logged in seconds.</p>
          <div className="hero-actions">
            <DownloadButton />
            <a className="secondary-button" href="/app/">
              <span>Try now for free</span>
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
          <FinalDashboardMockup />
        </div>
      </section>

      <footer className="footer-panel">
        <div className="footer-brand">
          <a className="footer-logo" href="/">
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
          <p>Download LogCal AI</p>
          <div className="store-row">
            <StoreBadge />
          </div>
        </div>

        <nav className="footer-column" aria-label="Legal">
          <h3>Legal</h3>
          <a href="/privacy/">Privacy Policy</a>
        </nav>

        <nav className="footer-column" aria-label="Company">
          <h3>Company</h3>
          <a href="/blog/">Blogs</a>
          <a href="mailto:johriantriksh24@gmail.com">Contact Us</a>
          <a href="/support/">Support</a>
        </nav>

        <div className="footer-bottom">
          <span>&copy; Copyright 2026, All rights reserved</span>
        </div>
      </footer>
    </div>
  );
}
