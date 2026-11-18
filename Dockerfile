# Container build for hosts other than Vercel (used for a Spring Winter deploy test).
# Builds the Next.js app, then on start applies new migrations and serves on :3000.
FROM node:24-bookworm-slim AS deps
WORKDIR /app
COPY package.json package-lock.json .npmrc* ./
RUN npm ci --no-audit --no-fund

FROM node:24-bookworm-slim AS build
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:24-bookworm-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production     NEXT_TELEMETRY_DISABLED=1     PORT=3000     HOSTNAME=0.0.0.0     NODE_EXTRA_CA_CERTS=/app/certs/rds-global-bundle.pem
COPY --from=build --chown=node:node /app ./
RUN mkdir -p /app/.data && chown -R node:node /app/.data
USER node
EXPOSE 3000
CMD ["sh", "-c", "node db/migrate.mjs && exec node_modules/.bin/next start -H 0.0.0.0 -p 3000"]
