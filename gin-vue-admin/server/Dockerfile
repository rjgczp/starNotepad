FROM crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles:base-alpine-latest-20260710

LABEL MAINTAINER="SliverHorn@sliver_horn@qq.com"
# 设置时区。容器复用宿主机时钟，无需在运行镜像内安装 NTP 服务。
ENV TZ=Asia/Shanghai
RUN if [ -e "/usr/share/zoneinfo/$TZ" ]; then \
      ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime; \
    fi \
    && echo "$TZ" > /etc/timezone

WORKDIR /go/src/github.com/flipped-aurora/gin-vue-admin/server

COPY .docker/gva-server ./server
COPY resource ./resource/
COPY config.docker.yaml ./

# 挂载目录：如果使用了sqlite数据库，容器命令示例：docker run -d -v /宿主机路径/gva.db:/go/src/github.com/flipped-aurora/gin-vue-admin/server/gva.db -p 8888:8888 --name gva-server-v1 gva-server:1.0
# VOLUME ["/go/src/github.com/flipped-aurora/gin-vue-admin/server"]

EXPOSE 8888
ENTRYPOINT ["./server", "-c", "config.docker.yaml"]
