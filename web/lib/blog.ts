export type BlogBlock =
  | { type: "paragraph"; text: string }
  | { type: "list"; items: string[] }
  | { type: "quote"; text: string }
  | { type: "callout"; title: string; text: string }
  | { type: "image"; src: string; alt: string; caption: string }
  | { type: "subheading"; text: string };

export type BlogSection = {
  id: string;
  heading: string;
  blocks: BlogBlock[];
};

export type BlogPost = {
  slug: string;
  title: string;
  seoTitle: string;
  description: string;
  date: string;
  readTime: string;
  category: string;
  heroImage: string;
  heroAlt: string;
  primaryKeyword: string;
  excerpt: string;
  intentSummary: string;
  sections: BlogSection[];
  faqs: Array<{ question: string; answer: string }>;
  imageIdeas: Array<{ idea: string; alt: string }>;
};

export const blogPosts: BlogPost[] = [
  {
    slug: "how-to-track-calories-without-weighing-food",
    title: "How to Track Calories Without Weighing Food",
    seoTitle: "Track Calories Without Weighing Food",
    description:
      "Learn how to track calories without weighing food using portions, habits, photos, and simple estimates. LogCal AI can make it easier.",
    date: "2026-05-11",
    readTime: "8 min read",
    category: "Calorie Tracking",
    heroImage: "/blog/calorie-tracking-without-scale.webp",
    heroAlt:
      "Balanced meal plate with portion sections beside a phone showing meal logged",
    primaryKeyword: "how to track calories without weighing food",
    excerpt:
      "A practical, low-stress way to estimate meals, log consistently, and build better eating habits without using a food scale every day.",
    intentSummary:
      "Readers want calorie tracking to feel less strict and time-consuming. This guide gives them a realistic system for everyday meals while showing where LogCal AI can reduce logging friction.",
    sections: [
      {
        id: "can-you-track-calories-without-a-food-scale",
        heading: "Can You Track Calories Without a Food Scale?",
        blocks: [
          {
            type: "paragraph",
            text: "You can track calories without weighing food by using portion estimates, repeat meals, photos, and quick meal logs. It will not be as exact as weighing every ingredient, but it can be accurate enough to understand your eating patterns and make better choices."
          },
          {
            type: "paragraph",
            text: "A food scale gives more precision, especially if you are tracking macros closely or following a strict nutrition plan. But many people do not need perfect numbers every day. They need a realistic system they can actually follow."
          },
          {
            type: "list",
            items: [
              "You may notice your snacks add more calories than expected.",
              "You may realise your lunch is lighter than your dinner.",
              "You may see that weekend meals are harder to track.",
              "You may find that drinks, dressings, or cooking oils are easy to forget."
            ]
          }
        ]
      },
      {
        id: "why-weighing-every-meal-is-hard",
        heading: "Why Weighing Every Meal Is Hard to Stick With",
        blocks: [
          {
            type: "paragraph",
            text: "Weighing food can work well at home, but real life gets messy. You may eat at restaurants, order takeaway, cook family-style meals, or have homemade food where no one measured every ingredient."
          },
          {
            type: "paragraph",
            text: "That is why many people stop calorie tracking. The process feels too detailed, so they give up completely."
          },
          {
            type: "callout",
            title: "A lighter system is better than no system",
            text: "If the choice is between estimating your meals or not logging them at all, estimating is usually the better habit."
          }
        ]
      },
      {
        id: "how-to-track-calories-without-weighing-food",
        heading: "How to Track Calories Without Weighing Food",
        blocks: [
          {
            type: "paragraph",
            text: "Here are practical ways to track calories without weighing food."
          },
          {
            type: "subheading",
            text: "Use the plate method for quick estimates"
          },
          {
            type: "paragraph",
            text: "Think of your plate like a simple map, not a strict rule. For a balanced meal, roughly half the plate is lighter foods like vegetables or salad, one smaller section is protein, one smaller section is carbs, and any oil, dressing, cheese, nuts, or creamy sauce is counted separately."
          },
          {
            type: "paragraph",
            text: "For example, if you eat a rice bowl with chicken or tofu, vegetables, yoghurt, and olive oil, you can log it as: one smaller section rice, one smaller section protein, half plate vegetables, small bowl yoghurt, and one spoon oil. It is still an estimate, but it is much clearer than just writing \"lunch\"."
          },
          {
            type: "subheading",
            text: "Use simple portion sizes"
          },
          {
            type: "paragraph",
            text: "Instead of guessing in grams, describe portions in everyday terms. A good log is less about perfect measurement and more about giving enough context for a realistic estimate."
          },
          {
            type: "list",
            items: [
              "Plate: useful for full meals, such as a small plate, regular plate, or large plate.",
              "Bowl: useful for foods like rice, pasta, oats, soup, yoghurt, or mixed meals.",
              "Cup: useful for cooked grains, cereal, fruit, milk, or yoghurt.",
              "Spoon: useful for oil, butter, dressing, nut butter, sauces, or dips.",
              "Small handful: useful for nuts, chips, crackers, berries, or other snacks."
            ]
          },
          {
            type: "paragraph",
            text: "For example, \"one regular plate of pasta with chicken, vegetables, and two spoons of creamy sauce\" is much clearer than \"pasta\". The same idea works for a sandwich, soup bowl, salad, rice bowl, or takeaway meal."
          },
          {
            type: "image",
            src: "/blog/meal-log-example.webp",
            alt: "Example of a vague food log becoming a more detailed calorie tracking entry",
            caption: "Better meal descriptions make calorie estimates more useful, even without exact weights."
          },
          {
            type: "subheading",
            text: "Repeat simple meals during the week"
          },
          {
            type: "paragraph",
            text: "You do not need to eat the same thing every day, but repeat meals make calorie tracking easier. Once you estimate a meal a few times, you start to understand its usual calorie range."
          },
          {
            type: "subheading",
            text: "Take photos before you eat"
          },
          {
            type: "paragraph",
            text: "A quick meal photo can help you remember portions later, especially when you are eating out, travelling, or too busy to log immediately."
          },
          {
            type: "subheading",
            text: "Log meals right away"
          },
          {
            type: "quote",
            text: "Grilled chicken, one cup of rice, roasted vegetables, yoghurt, and one spoon of olive oil."
          },
          {
            type: "paragraph",
            text: "That kind of detail is much better than trying to remember everything at night. If typing feels slow, LogCal AI lets you log meals by voice, text, or photo, so you can capture the meal while it is still fresh in your mind."
          },
          {
            type: "subheading",
            text: "Estimate cooking oils, sauces, and extras"
          },
          {
            type: "paragraph",
            text: "The main meal is usually easier to remember than the extras. But oil, butter, dressing, mayo, cheese, cream sauces, nuts, sugary drinks, alcohol, and dessert bites can change the total estimate a lot."
          }
        ]
      },
      {
        id: "simple-lunch-example",
        heading: "A Simple Example: Estimating a Normal Lunch",
        blocks: [
          {
            type: "paragraph",
            text: "Let us say you had a bowl with rice, grilled chicken or tofu, roasted vegetables, yoghurt, and a spoon of olive oil."
          },
          {
            type: "paragraph",
            text: "A vague log would be: lunch bowl. A better log would be: one cup cooked rice, one serving of chicken or tofu, one serving roasted vegetables, a small bowl of yoghurt, and one spoon of olive oil."
          },
          {
            type: "paragraph",
            text: "The second version is still not weighed, but it gives enough detail for a useful estimate. It includes quantity, food type, and the calorie-dense extra."
          }
        ]
      },
      {
        id: "when-you-should-be-more-precise",
        heading: "When You Should Be More Precise",
        blocks: [
          {
            type: "paragraph",
            text: "Estimating works well for everyday awareness, but there are times when weighing food or using exact labels may be useful."
          },
          {
            type: "list",
            items: [
              "You have a medical condition and your diet needs professional guidance.",
              "You are preparing for a sport, event, or strict physique goal.",
              "Your weight has not changed for several weeks and you want to troubleshoot.",
              "You often eat calorie-dense foods where small portions matter.",
              "You are tracking macros closely, not just calories."
            ]
          },
          {
            type: "callout",
            title: "A quick health note",
            text: "Calorie estimates vary based on ingredients, cooking methods, portions, and brands. LogCal AI can help estimate meals, but it should not replace medical or nutrition advice. If you have a health condition or specific dietary needs, speak with a qualified professional."
          }
        ]
      },
      {
        id: "how-logcal-ai-can-help",
        heading: "How LogCal AI Can Help",
        blocks: [
          {
            type: "paragraph",
            text: "The hardest part of calorie tracking is not always knowing what to eat. It is logging consistently."
          },
          {
            type: "paragraph",
            text: "LogCal AI is built for that exact problem. Instead of searching through long food databases, you can describe your meal in plain language, speak it out loud, or upload a photo. The app gives you a calorie estimate and keeps your day easier to track."
          },
          {
            type: "image",
            src: "/blog/logcal-voice-meal-logging.webp",
            alt: "LogCal AI voice meal logging screen listening to a meal description",
            caption: "LogCal AI can capture a meal by voice while the details are still fresh."
          },
          {
            type: "quote",
            text: "Rice bowl with beans, salad, yoghurt, and a spoon of olive oil."
          },
          {
            type: "paragraph",
            text: "This makes calorie tracking feel less like admin and more like a quick habit. You still need to be honest about portions, but you do not need to weigh every meal to get started."
          }
        ]
      },
      {
        id: "common-mistakes-to-avoid",
        heading: "Common Mistakes to Avoid",
        blocks: [
          {
            type: "list",
            items: [
              "Logging only the main food and forgetting oils, sauces, cheese, drinks, or dessert bites.",
              "Using tiny portions in your log when the portion was actually large.",
              "Forgetting snacks like biscuits, nuts, chocolates, or bites while cooking.",
              "Trying to be perfect instead of simply logging the next meal.",
              "Changing your estimating style every day, which makes your data harder to read."
            ]
          }
        ]
      },
      {
        id: "final-thoughts",
        heading: "Final Thoughts",
        blocks: [
          {
            type: "paragraph",
            text: "You can track calories without weighing food if you use a consistent system. Start with portion estimates, include sauces and oils, take meal photos when useful, and log meals before you forget the details."
          },
          {
            type: "paragraph",
            text: "The goal is not to create perfect numbers. The goal is to understand your eating habits well enough to make better choices."
          },
          {
            type: "callout",
            title: "Try LogCal AI",
            text: "If you want an easier way to track calories without weighing food, try LogCal AI. You can log meals with text, voice, or photos and get practical calorie estimates without searching through endless food lists."
          }
        ]
      }
    ],
    faqs: [
      {
        question: "Is calorie tracking without weighing food accurate?",
        answer:
          "It is less precise than weighing food, but it can still be useful. The goal is to estimate consistently, include key details, and notice patterns in your eating habits."
      },
      {
        question: "What is the easiest way to estimate calories?",
        answer:
          "Start by describing the meal clearly: food items, rough portions, cooking method, and extras like oil, cheese, sauces, or drinks. Photos can also help you remember portions."
      },
      {
        question: "Can I lose weight without weighing my food?",
        answer:
          "Many people can make progress without weighing food by tracking portions, eating consistently, and staying aware of calorie-dense extras. Weight loss needs vary by person, so speak with a professional if you need personal guidance."
      },
      {
        question: "Should I weigh food or estimate calories?",
        answer:
          "Use the method you can stick with. Weighing is more precise, but estimating is easier for restaurants, homemade meals, and busy days. A mix of both can work well."
      },
      {
        question: "How does LogCal AI estimate calories?",
        answer:
          "LogCal AI uses the meal details you provide through text, voice, or photos to create a calorie estimate. The more specific you are about portions and ingredients, the more useful the estimate can be."
      }
    ],
    imageIdeas: [
      {
        idea: "A simple plate split into protein, carbs, vegetables, and fats.",
        alt: "Plate method example for tracking calories without weighing food"
      },
      {
        idea: "A phone screen showing a voice meal log for a normal lunch.",
        alt: "LogCal AI voice food logging for a calorie estimate"
      },
      {
        idea: "Side-by-side example of a vague food log and a detailed food log.",
        alt: "Example of a better meal description for calorie tracking"
      }
    ]
  }
];

export function getBlogPost(slug: string) {
  return blogPosts.find((post) => post.slug === slug);
}
