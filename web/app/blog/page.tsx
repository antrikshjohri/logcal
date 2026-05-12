import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

import { blogPosts } from "../../lib/blog";

export const metadata: Metadata = {
  title: "Blog",
  description:
    "Simple, useful guides from LogCal AI on calorie tracking, food logging, and healthier eating habits.",
  alternates: {
    canonical: "/blog/"
  }
};

export default function BlogIndexPage() {
  const [featuredPost, ...otherPosts] = blogPosts;

  return (
    <div className="blog-page">
      <section className="blog-hero">
        <div className="blog-hero-copy">
          <span className="eyebrow">LogCal AI Blog</span>
          <h1>Simple guides for easier calorie tracking</h1>
          <p>
            Practical, friendly advice for logging meals, estimating calories,
            and building healthier eating habits without making food feel like
            homework.
          </p>
        </div>
        <div className="blog-hero-art" aria-hidden="true">
          <span className="blog-art-card blog-art-card-main">
            <strong>Voice log</strong>
            <i />
            <i />
            <i />
          </span>
          <span className="blog-art-card blog-art-card-small">
            <strong>520 kcal</strong>
            <span>estimated</span>
          </span>
          <span className="blog-art-plate" />
        </div>
      </section>

      <section className="blog-featured-grid" aria-label="Featured blog post">
        <Link
          className="blog-feature-card"
          href={`/blog/${featuredPost.slug}/`}
        >
          <span className="blog-card-image-wrap">
            <Image
              src={featuredPost.heroImage}
              alt={featuredPost.heroAlt}
              width={1200}
              height={760}
              className="blog-card-image"
              priority
              fetchPriority="high"
              sizes="(max-width: 1200px) 100vw, 650px"
            />
          </span>
          <span className="blog-card-content">
            <span className="blog-meta">
              {featuredPost.category} · {featuredPost.readTime}
            </span>
            <h2>{featuredPost.title}</h2>
            <p>{featuredPost.excerpt}</p>
            <span className="blog-read-link">Read article</span>
          </span>
        </Link>

        <aside className="blog-topic-panel">
          <h2>Start with these guides</h2>
          <div className="blog-topic-list">
            <Link href="/blog/how-to-estimate-portion-sizes/">
              Estimate portions without weighing food
            </Link>
            <Link href="/blog/best-way-to-track-calories-for-weight-loss/">
              Track calories for weight loss without perfection
            </Link>
            <Link href="/blog/photo-calorie-tracking/">
              Use meal photos for clearer food logs
            </Link>
            <Link href="/blog/calorie-tracking-habit/">
              Build a calorie tracking habit that sticks
            </Link>
          </div>
        </aside>
      </section>

      {otherPosts.length > 0 && (
        <section className="blog-grid" aria-label="All blog posts">
          {otherPosts.map((post) => (
            <Link className="blog-card" href={`/blog/${post.slug}/`} key={post.slug}>
              <Image
                src={post.heroImage}
                alt={post.heroAlt}
                width={1200}
                height={760}
                sizes="(max-width: 900px) 100vw, 33vw"
              />
              <span>{post.category}</span>
              <h2>{post.title}</h2>
              <p>{post.excerpt}</p>
            </Link>
          ))}
        </section>
      )}
    </div>
  );
}
