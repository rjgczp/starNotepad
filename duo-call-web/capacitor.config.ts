import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "ski.xiaoyu.duo",
  appName: "情侣小屋",
  webDir: "dist",
  server: {
    androidScheme: "https",
    hostname: "localhost",
  },
};

export default config;
