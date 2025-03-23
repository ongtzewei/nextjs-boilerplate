#Install dependencies only when needed
FROM node:22.14.0-alpine3.21 AS deps
WORKDIR /nextjs/boilerplate-app
RUN corepack enable pnpm

COPY .npmrc package.json pnpm-lock.yaml ./
RUN apk add --no-cache openssl3
RUN pnpm install --frozen-lockfile

# Rebuild the source code only when needed
FROM node:22.14.0-alpine3.21 AS builder
WORKDIR /nextjs/boilerplate-app
RUN corepack enable pnpm

COPY . .
COPY --from=deps /nextjs/boilerplate-app/node_modules ./node_modules
RUN pnpm prisma:generate
RUN pnpm build

# Production image, copy all the files and run next
FROM node:22.14.0-alpine3.21 AS runner
WORKDIR /nextjs/boilerplate-app
RUN corepack enable pnpm

# ENV NODE_ENV production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S webapp -u 1001
RUN chown -R webapp:nodejs /nextjs/boilerplate-app ./
COPY --from=builder --chown=webapp:nodejs /nextjs/boilerplate-app/ ./

USER webapp
EXPOSE 3000
CMD ["pnpm", "start:prod"]
