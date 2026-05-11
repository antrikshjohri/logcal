import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";

import type { BlogBlock } from "../../../lib/blog";
import { blogPosts, getBlogPost } from "../../../lib/blog";

const appStoreUrl =
  "https://apps.apple.com/us/app/logcal-ai-calorie-tracker/id6757228315";

type PageProps = {
  params: Promise<{ slug: string }>;
};

export function generateStaticParams() {
  return blogPosts.map((post) => ({ slug: post.slug }));
}

export async function generateMetadata({
  params
}: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const post = getBlogPost(slug);

  if (!post) {
    return {};
  }

  return {
    title: post.seoTitle,
    description: post.description,
    alternates: {
      canonical: `/blog/${post.slug}/`
    },
    openGraph: {
      title: post.seoTitle,
      description: post.description,
      url: `https://logcalai.com/blog/${post.slug}/`,
      type: "article",
      images: [
        {
          url: post.heroImage,
          width: 1200,
          height: 760,
          alt: post.heroAlt
        }
      ]
    }
  };
}

function renderBlock(block: BlogBlock, index: number) {
  if (block.type === "paragraph") {
    return <p key={index}>{block.text}</p>;
  }

  if (block.type === "list") {
    return (
      <ul key={index}>
        {block.items.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    );
  }

  if (block.type === "quote") {
    return <blockquote key={index}>{block.text}</blockquote>;
  }

  if (block.type === "callout") {
    return (
      <aside className="article-callout" key={index}>
        <strong>{block.title}</strong>
        <p>{block.text}</p>
      </aside>
    );
  }

  if (block.type === "image") {
    const isContainedImage = block.src.includes("logcal-voice-meal-logging");

    return (
      <figure
        className={`article-image-card ${
          isContainedImage ? "article-image-card-contained" : ""
        }`}
        key={index}
      >
        <Image
          src={block.src}
          alt={block.alt}
          width={isContainedImage ? 360 : 1200}
          height={isContainedImage ? 761 : 760}
          sizes={isContainedImage ? "275px" : "(max-width: 900px) 100vw, 760px"}
        />
        <figcaption>{block.caption}</figcaption>
      </figure>
    );
  }

  return <h3 key={index}>{block.text}</h3>;
}

export default async function BlogArticlePage({ params }: PageProps) {
  const { slug } = await params;
  const post = getBlogPost(slug);

  if (!post) {
    notFound();
  }

  const blogPostingSchema = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    "@id": `https://logcalai.com/blog/${post.slug}/#blogposting`,
    headline: post.seoTitle,
    description: post.description,
    url: `https://logcalai.com/blog/${post.slug}/`,
    datePublished: post.date,
    dateModified: post.date,
    author: {
      "@type": "Organization",
      name: "LogCal AI"
    },
    publisher: {
      "@type": "Organization",
      name: "LogCal AI",
      logo: {
        "@type": "ImageObject",
        url: "https://logcalai.com/images/logcal-transparent-logo.png"
      }
    },
    mainEntityOfPage: {
      "@type": "WebPage",
      "@id": `https://logcalai.com/blog/${post.slug}/`
    }
  };

  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "@id": `https://logcalai.com/blog/${post.slug}/#faq`,
    mainEntity: post.faqs.map((faq) => ({
      "@type": "Question",
      name: faq.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: faq.answer
      }
    }))
  };

  return (
    <article className="blog-article">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(blogPostingSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />

      <header className="article-hero">
        <div className="article-hero-copy">
          <Link className="article-back-link" href="/blog/">
            Blogs
          </Link>
          <span className="blog-meta">
            {post.category} · {post.readTime}
          </span>
          <h1>{post.title}</h1>
          <p>{post.description}</p>
        </div>
        <figure className="article-hero-image">
          <Image
            src={post.heroImage}
            alt={post.heroAlt}
            width={1200}
            height={760}
            priority
            fetchPriority="high"
            sizes="(max-width: 900px) 100vw, 45vw"
          />
        </figure>
      </header>

      <div className="article-layout">
        <aside className="article-toc" aria-label="Article sections">
          <span>In this guide</span>
          {post.sections.map((section) => (
            <a href={`#${section.id}`} key={section.id}>
              {section.heading}
            </a>
          ))}
        </aside>

        <div className="article-content">
          {post.sections.map((section) => (
            <section id={section.id} key={section.id}>
              <h2>{section.heading}</h2>
              {section.blocks.map(renderBlock)}
            </section>
          ))}

          <section id="faq" className="article-faq">
            <h2>FAQ</h2>
            {post.faqs.map((faq) => (
              <details key={faq.question}>
                <summary>{faq.question}</summary>
                <p>{faq.answer}</p>
              </details>
            ))}
          </section>

          <section className="article-final-cta">
            <h2>Make meal logging easier</h2>
            <p>
              LogCal AI lets you track meals with text, voice, or photos, so
              calorie tracking can fit into real life.
            </p>
            <a href={appStoreUrl} target="_blank" rel="noreferrer">
              Download LogCal AI
            </a>
          </section>
        </div>
      </div>
    </article>
  );
}
