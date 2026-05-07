import type { Metadata } from "next";
import MinecraftMapEmbed from "@/app/components/minecraft-map-embed";

export const metadata: Metadata = {
  title: "Minecraft World Viewer",
  description: "Interactive 3D preview page for uploaded Minecraft worlds.",
};

export default function MinecraftPage() {
  const mapUrl = process.env.MINECRAFT_MAP_URL || "http://localhost:8100";
  return <MinecraftMapEmbed mapUrl={mapUrl} worldPath="BlueMap Active World" />;
}
