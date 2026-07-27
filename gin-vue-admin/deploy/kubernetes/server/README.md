# GVA Server Kubernetes 配置

部署清单不会保存数据库密码、JWT 签名密钥或邮件授权码。部署前先创建本地密钥文件：

```bash
cp .env.kubernetes.example .env.kubernetes
```

填写 `.env.kubernetes` 后创建 Secret：

```bash
kubectl create secret generic gva-secrets \
  --from-env-file=.env.kubernetes
```

`.env.kubernetes` 会被仓库根目录的 `.gitignore` 忽略，不要提交该文件。随后应用 ConfigMap、Deployment 和 Service：

```bash
kubectl apply -f gva-server-configmap.yaml
kubectl apply -f gva-server-deployment.yaml
kubectl apply -f gva-server-service.yaml
```
