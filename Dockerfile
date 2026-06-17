# syntax=docker/dockerfile:1.7

# ---- builder stage ----
FROM node:20-alpine AS builder
WORKDIR /build

COPY app/package*.json ./
RUN npm ci --omit=dev --no-audit --no-fund

COPY app/ ./

# ---- runtime stage (distroless, non-root) ----
FROM gcr.io/distroless/nodejs20-debian12:nonroot
WORKDIR /app

COPY --from=builder --chown=nonroot:nonroot /build /app

ENV NODE_ENV=production \
    PORT=8080
EXPOSE 8080

USER nonroot
CMD ["src/index.js"]
