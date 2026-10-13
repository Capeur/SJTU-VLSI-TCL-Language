import { defineCollection, z } from 'astro:content';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';

// Lesson frontmatter — PRD §8.1. All fields optional so non-lesson pages (home, about…) validate.
export const collections = {
  docs: defineCollection({
    loader: docsLoader(),
    schema: docsSchema({
      extend: z.object({
        milestone: z.enum(['m10', 'm20', 'm30', 'm40']).optional(),
        week: z.number().int().min(1).max(40).optional(),
        lesson: z.enum(['a', 'b', 'lab', 'quiz', 'capstone', 'exam']).optional(),
        minutes: z.number().int().min(0).optional(),
        goals: z.array(z.string()).max(3).optional(),
        prerequisites: z.array(z.string()).optional(),
        glossary: z.array(z.string()).optional(),
        tcl_min: z.string().optional(),
        sources: z.array(z.object({ title: z.string(), url: z.string().url() })).optional(),
        runs_in: z.array(z.enum(['playground', 'terminal', 'drvlite', 'klayout'])).optional(),
        ai_assisted: z.boolean().optional(),
        reviewed_by: z.string().optional(),
        review_date: z.string().regex(/^(\d{4}-\d{2}-\d{2})?$/).optional(),
      }),
    }),
  }),
};
