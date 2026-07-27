FROM crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles:base-node-22-alpine-20260710 AS build
WORKDIR /app
COPY package*.json ./
RUN npm config set registry https://registry.npmmirror.com && \
    for i in 1 2 3 4 5; do npm ci && break || sleep 10; done
COPY . .
RUN npm run build

FROM crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles:base-nginx-alpine-20260710
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
