import type { MetadataRoute } from "next";

import { blogPosts } from "../lib/blog";

const siteUrl = "https://logcalai.com";

export const dynamic = "force-static";

export default function sitemap(): MetadataRoute.Sitemap {
  const staticRoutes: MetadataRoute.Sitemap = [
    {
      url: `${siteUrl}/`,
      changeFrequency: "monthly",
      priority: 1
    },
    {
      url: `${siteUrl}/app/`,
      changeFrequency: "monthly",
      priority: 0.8
    },
    {
      url: `${siteUrl}/features/`,
      changeFrequency: "monthly",
      priority: 0.8
    },
    {
      url: `${siteUrl}/blog/`,
      changeFrequency: "weekly",
      priority: 0.9
    },
    {
      url: `${siteUrl}/privacy/`,
      changeFrequency: "yearly",
      priority: 0.3
    },
    {
      url: `${siteUrl}/support/`,
      changeFrequency: "monthly",
      priority: 0.5
    },
    {
      url: `${siteUrl}/terms/`,
      changeFrequency: "yearly",
      priority: 0.3
    }
  ];

  const blogRoutes: MetadataRoute.Sitemap = blogPosts.map((post) => ({
    url: `${siteUrl}/blog/${post.slug}/`,
    lastModified: post.date,
    changeFrequency: "monthly",
    priority: 0.8
  }));

  return [...staticRoutes, ...blogRoutes];
}
