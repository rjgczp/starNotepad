import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, ".", "");
  return {
    plugins: [react()],
    server: {
      host: "0.0.0.0",
      port: 3002,
      proxy: {
        "/api": {
          target: env.DUO_API_PROXY || "http://127.0.0.1:8888",
          changeOrigin: true,
          ws: true,
        },
        "/uploads": {
          target: env.DUO_API_PROXY || "http://127.0.0.1:8888",
          changeOrigin: true,
        },
      },
    },
  };
});
