import { defineRouteMiddleware } from '@astrojs/starlight/route-data';

// PRD §0 rule 8: content with an empty `reviewed_by` shows a visible Draft banner.
export const onRequest = defineRouteMiddleware((context) => {
  const { entry } = context.locals.starlightRoute;
  const data = entry.data as { milestone?: string; reviewed_by?: string };
  const isCoursePage = data.milestone !== undefined;
  if (isCoursePage && !data.reviewed_by) {
    context.locals.starlightRoute.entry.data.banner = {
      content: 'Draft — not yet reviewed',
    };
  }
});
