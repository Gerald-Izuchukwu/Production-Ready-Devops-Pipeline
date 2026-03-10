FROM node:20-alpine AS builder

WORKDIR /app

COPY package*json ./

RUN npm ci --only=production

FROM node:18-alpine AS production

RUN addgroup -S devgroup && adduser -S dev -G devgroup

WORKDIR /app

COPY --from=Builder /app/node_modules ./node_modules
COPY . .

RUN chown -R dev:devgroup /app

USER dev

EXPOSE 3000

CMD [ "node", "app.js" ]