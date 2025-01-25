# Use an existing image as a base
FROM node:22-slim as base

ENV APP_DIR="app"
ENV UI_DIR="ui"

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

COPY . /app
WORKDIR /app

FROM base AS prod-app-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm --prefix=$APP_DIR install --prod --frozen-lockfile

FROM base AS build-app
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm --prefix=$APP_DIR install --frozen-lockfile
RUN pnpm --prefix $APP_DIR run build

## ui
FROM base AS prod-ui
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm --prefix=$UI_DIR install --frozen-lockfile
RUN pnpm --prefix $UI_DIR run build


FROM base
COPY --from=prod-app-deps /app/$APP_DIR/node_modules /app/node_modules
COPY --from=build-app /app/$APP_DIR/dist /app
COPY --from=prod-ui /$UI_DIR/ui/dist/power-data-ui/browser /app/client


# Expose the port that the app listens on
EXPOSE 3000

# Define the command to run the app
CMD ["node", "main.js"]