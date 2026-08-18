import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";
import { readFileSync } from "node:fs";

const packageVersion = JSON.parse(
  readFileSync(new URL("./package.json", import.meta.url), "utf8"),
).version as string;

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, ".", "");
  return {
    base: mode === "native" ? "./" : "/",
    plugins: [react()],
    define: {
      __DUO_APP_VERSION__: JSON.stringify(env.VITE_DUO_APP_VERSION || packageVersion),
    },
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
