# Use an existing image as a base
FROM node:22-slim as base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

COPY . /app
WORKDIR /app

FROM base AS prod-app-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm --prefix=backend install --prod --frozen-lockfile

FROM base AS build-app
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm --prefix=backend install --frozen-lockfile
RUN pnpm --prefix backend run build

## ui
FROM base AS prod-ui
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm --prefix=ui --frozen-lockfile
RUN pnpm --prefix ui run build


FROM base
COPY --from=prod-app-deps /app/backend/node_modules /app/node_modules
COPY --from=build-app /app/backend/dist /app
COPY --from=prod-ui /app/ui/dist/power-data-ui/browser /app/client


# Expose the port that the app listens on
EXPOSE 3000

# Define the command to run the app
CMD ["node", "main.js"]