import { defineRouteMiddleware } from '@astrojs/starlight/route-data';

// PRD §0 rule 8: content with an empty `reviewed_by` shows a visible Draft banner.
export const onRequest = defineRouteMiddleware((context) => {
  const { entry } = context.locals.starlightRoute;
  const data = entry.data as { milestone?: string; ai_assisted?: boolean; reviewed_by?: string };
  // Course pages, plus any other page that declares it was AI-assisted (e.g. /start-here/).
  const needsReview = data.milestone !== undefined || data.ai_assisted === true;
  if (needsReview && !data.reviewed_by) {
    context.locals.starlightRoute.entry.data.banner = {
      content: 'Draft — not yet reviewed',
    };
  }
});
