#Install dependencies only when needed
FROM node:18.20.3-alpine3.19 AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
# RUN apk add --no-cache libc6-compat

WORKDIR /nextjs/boilerplate-app
COPY .npmrc package.json package-lock.json ./
ARG NPM_CI_TOKEN 
ENV NPM_CI_TOKEN $NPM_CI_TOKEN
RUN npm ci

# Rebuild the source code only when needed
FROM node:18.20.3-alpine3.19 AS builder
WORKDIR /nextjs/boilerplate-app
COPY . .
COPY --from=deps /nextjs/boilerplate-app/node_modules ./node_modules
RUN npm run prisma:generate

# Production image, copy all the files and run next
FROM node:18.20.3-alpine3.19 AS runner
WORKDIR /nextjs/boilerplate-app

ENV NODE_ENV production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S webapp -u 1001

RUN chown -R webapp:nodejs /nextjs/boilerplate-app ./
COPY --from=builder --chown=webapp:nodejs /nextjs/boilerplate-app/ ./

USER webapp
EXPOSE 3000

CMD ["npm", "run", "start:prod"]
