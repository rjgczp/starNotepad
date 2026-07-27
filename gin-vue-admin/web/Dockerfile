FROM --platform=$BUILDPLATFORM crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles:base-node-22-alpine-20260710 AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm config set registry https://registry.npmmirror.com && npm ci
COPY . .
RUN npm run build

FROM crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles:base-nginx-alpine-20260710
COPY nginx.production.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
