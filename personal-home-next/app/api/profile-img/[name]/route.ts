import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { NextResponse } from "next/server";

const IMAGE_DIR = path.join(process.cwd(), "data", "img");

const MIME_BY_EXT: Record<string, string> = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
};

function getMimeType(fileName: string): string {
  const ext = path.extname(fileName).toLowerCase();
  return MIME_BY_EXT[ext] || "application/octet-stream";
}

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ name: string }> | { name: string } }
) {
  const resolvedParams = await params;
  const rawName = decodeURIComponent(resolvedParams?.name || "").trim();
  if (!rawName) {
    return NextResponse.json({ message: "invalid image name" }, { status: 400 });
  }

  const normalized = rawName.toLowerCase();

  try {
    const files = await readdir(IMAGE_DIR);
    const target = files.find((file) => {
      const fileLower = file.toLowerCase();
      if (normalized.includes(".")) {
        return fileLower === normalized;
      }
      return path.parse(file).name.toLowerCase() === normalized;
    });

    if (!target) {
      return NextResponse.json({ message: "image not found" }, { status: 404 });
    }

    const fullPath = path.join(IMAGE_DIR, target);
    const content = await readFile(fullPath);

    return new NextResponse(content, {
      status: 200,
      headers: {
        "Content-Type": getMimeType(target),
        "Cache-Control": "public, max-age=3600",
      },
    });
  } catch {
    return NextResponse.json({ message: "failed to load image" }, { status: 500 });
  }
}
