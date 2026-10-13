# Production Multi-Stage Dockerfile for Google Cloud Run / Container Deployment
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=8080

COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
COPY server.js ./

EXPOSE 8080

USER node
CMD ["node", "server.js"]
