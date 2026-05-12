# SEO Blog Article Prompt Template

Copy this prompt when you want to generate a new LogCal AI blog article.

```text
Act as the LogCal AI SEO Blog Writer.

Create a complete SEO blog article package using the details below.

Blog topic:
{{BLOG_TOPIC}}

Primary keyword:
{{PRIMARY_KEYWORD}}

Secondary keywords:
{{SECONDARY_KEYWORDS}}

Target audience:
{{TARGET_AUDIENCE}}

Search intent:
{{SEARCH_INTENT}}

Desired article length:
{{DESIRED_ARTICLE_LENGTH}}

Internal links to include:
{{INTERNAL_LINKS}}

CTA to include:
{{CTA}}

Competitor/reference URLs, optional:
{{REFERENCE_URLS}}

Region focus, optional:
{{REGION_FOCUS}}

Product context:
LogCal AI is an AI calorie tracker where users can log meals using text, voice, or images and get calorie estimates. The audience is people trying to lose weight, track calories, build healthier eating habits, and log food easily.

Tone:
Simple, useful, friendly, specific, non-generic, not overly formal, and not obviously AI-written.

Return:
1. SEO title, under 60 characters
2. Meta description, under 155 characters
3. URL slug
4. Internal search intent summary, marked "Do not publish"
5. Article outline with H1, H2, and H3 structure
6. Production-ready full blog article in Markdown
7. FAQ section to publish
8. Suggested internal links
9. Image plan with alt text and ChatGPT image-generation prompts
10. Suggested schema markup, especially BlogPosting and FAQPage JSON-LD
11. Final SEO checklist, marked "Do not publish"

Writing rules:
- Prioritise helpful, people-first content, not keyword stuffing.
- Answer the user's query clearly in the first 100 words.
- Use the primary keyword naturally in the title, intro, at least one H2, and conclusion.
- Use secondary keywords naturally where relevant.
- Use short paragraphs, simple language, and scannable sections.
- Add practical examples wherever possible.
- Mention LogCal AI naturally only where useful, not in every paragraph.
- Include a soft CTA near the middle and a stronger CTA at the end.
- Avoid fake statistics, unsupported claims, medical claims, or exaggerated promises.
- For health/nutrition topics, include a light disclaimer that calorie estimates vary and users should consult a professional for medical advice.
- Keep the writing human, specific, and useful.
- Default to global, region-agnostic food examples unless a region focus is explicitly provided.
- Avoid region-specific dishes or terms unless the article is explicitly regional.
- Prefer broadly understood food examples: rice bowls, pasta, sandwiches, soup, salads, oats, yoghurt, eggs, chicken, fish, tofu, beans, lentils, vegetables, fruit, olive oil, dressing, sauces, and nuts.
- Explain portion sizes with practical terms like plate, bowl, cup, spoon, small handful, and small/regular/large serving.
- Do not include visible production article sections called "Search intent", "SEO checklist", "Image ideas", "Image ideas to replace later", "Schema markup", or other internal planning labels.
- Keep image-generation prompts outside the published article body.

Image prompt requirements:
- Provide ChatGPT image-generation prompts for the blog cover image, at least one supporting article image, and one optional product/app image or screenshot direction.
- Each prompt should include intended placement, 1200x760 landscape unless another size is better, scene description, style direction, composition guidance, text guidance, avoid list, and suggested alt text.
- For blog cover images, do not include LogCal AI branding, logo, branded phone screens, or app mockups unless explicitly requested. Covers should feel like normal editorial blog visuals, not product ads.
- The cover visual must explain the article's main idea at thumbnail size. Do not make one supporting fact the entire image.
- Use text only when it helps comprehension; keep it large, short, and readable on mobile/blog-card previews.
- Visual style should feel premium, modern, clean, friendly, consumer health app, with soft off-white backgrounds, deep green accents, warm natural food colors, and no diet-culture/body-transformation imagery.
```
