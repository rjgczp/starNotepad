"use client";

import { useMemo, useRef, useState } from "react";

type VoxelBlock = {
  id: string;
  x: number;
  y: number;
  z: number;
  top: string;
  left: string;
  right: string;
};

export type MinecraftPreview = {
  worldPath: string;
  worldAbs: string;
  gridSize: number;
  regionCount: number;
  heights: number[][];
};

const SIZE = 22;
const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));

const buildBlocks = (heights: number[][]): VoxelBlock[] => {
  const blocks: VoxelBlock[] = [];
  const grid = heights.length;
  if (grid === 0) return blocks;

  const centerOffset = grid / 2;

  for (let z = 0; z < grid; z += 1) {
    for (let x = 0; x < grid; x += 1) {
      const height = Number.isFinite(heights[z]?.[x]) ? Math.max(1, heights[z][x]) : 1;

      const isWater = height <= 1;
      const isSand = height === 2;

      blocks.push({
        id: `${x}-${z}`,
        x: (x - centerOffset) * SIZE,
        y: -height * (SIZE * 0.72),
        z: (z - centerOffset) * SIZE,
        top: isWater ? "#60a5fa" : isSand ? "#d8b772" : "#72b968",
        left: isWater ? "#3b82f6" : isSand ? "#b68f47" : "#4e8e42",
        right: isWater ? "#2563eb" : isSand ? "#9a763c" : "#3e7135",
      });
    }
  }

  return blocks;
};

type MinecraftWorldViewerProps = {
  preview: MinecraftPreview | null;
  loadError?: string;
};

export default function MinecraftWorldViewer({ preview, loadError }: MinecraftWorldViewerProps) {
  const blocks = useMemo(() => buildBlocks(preview?.heights || []), [preview]);
  const dragRef = useRef<{ x: number; y: number; rotX: number; rotY: number } | null>(null);
  const [rotation, setRotation] = useState({ x: 58, y: -45 });
  const [zoom, setZoom] = useState(1);
  const [isDragging, setIsDragging] = useState(false);

  return (
    <main className="relative min-h-screen overflow-hidden bg-[radial-gradient(circle_at_16%_18%,#ffe7c4_0%,#ffe7c400_28%),radial-gradient(circle_at_84%_82%,#86efac_0%,#86efac00_30%),linear-gradient(145deg,#07120e_0%,#0f2f21_44%,#174737_100%)] text-emerald-50">
      <div className="absolute inset-0 bg-[linear-gradient(transparent_0%,rgba(4,10,8,0.78)_100%)]" />

      <section className="relative z-10 mx-auto flex w-full max-w-7xl flex-col gap-8 px-5 pb-10 pt-8 md:px-10 lg:flex-row lg:items-start lg:justify-between">
        <header className="max-w-xl space-y-4">
          <p className="inline-flex rounded-full border border-emerald-200/40 bg-emerald-200/10 px-3 py-1 text-xs tracking-[0.22em] text-emerald-100/90">
            MINECRAFT WORLD PREVIEW
          </p>
          <h1 className="text-4xl font-black leading-tight text-lime-100 md:text-6xl">
            /Minecraft
            <span className="block bg-gradient-to-r from-amber-200 via-lime-100 to-emerald-200 bg-clip-text text-transparent">
              3D 世界展示
            </span>
          </h1>
          <p className="text-sm leading-7 text-emerald-50/80 md:text-base">
            已接入后端世界预览接口，当前体素地形来自 `level.dat + region` 的简化高度图。支持拖拽旋转和滚轮缩放。
          </p>
          <div className="flex flex-wrap gap-2 text-xs text-emerald-100/90">
            <span className="rounded-full border border-emerald-100/30 bg-emerald-100/10 px-3 py-1">Drag: Rotate</span>
            <span className="rounded-full border border-emerald-100/30 bg-emerald-100/10 px-3 py-1">Wheel: Zoom</span>
            <span className="rounded-full border border-emerald-100/30 bg-emerald-100/10 px-3 py-1">Route: /Minecraft</span>
          </div>
        </header>

        <aside className="w-full max-w-md rounded-3xl border border-emerald-100/25 bg-black/20 p-5 backdrop-blur-md">
          <h2 className="text-lg font-bold text-emerald-100">当前世界路径</h2>
          <p className="mt-3 break-all rounded-xl border border-emerald-100/20 bg-black/30 px-3 py-2 text-xs leading-6 text-emerald-100/90">
            {preview?.worldAbs || "未加载到世界目录"}
          </p>
          <p className="mt-4 text-xs leading-6 text-emerald-100/75">
            {preview
              ? `region 文件数: ${preview.regionCount} · 网格: ${preview.gridSize}x${preview.gridSize}`
              : loadError || "请检查后端服务和世界路径配置。"}
          </p>
        </aside>
      </section>

      <section className="relative z-10 mx-auto mb-8 h-[66vh] w-[95vw] max-w-7xl rounded-[2rem] border border-emerald-100/20 bg-black/25 shadow-[0_24px_90px_rgba(0,0,0,0.45)] backdrop-blur-sm md:h-[72vh]">
        <div
          className="h-full w-full cursor-grab active:cursor-grabbing"
          style={{ perspective: "1200px" }}
          onMouseDown={(event) => {
            dragRef.current = {
              x: event.clientX,
              y: event.clientY,
              rotX: rotation.x,
              rotY: rotation.y,
            };
            setIsDragging(true);
          }}
          onMouseMove={(event) => {
            if (!dragRef.current) return;
            const dx = event.clientX - dragRef.current.x;
            const dy = event.clientY - dragRef.current.y;
            setRotation({
              x: clamp(dragRef.current.rotX - dy * 0.25, 22, 78),
              y: dragRef.current.rotY + dx * 0.4,
            });
          }}
          onMouseUp={() => {
            dragRef.current = null;
            setIsDragging(false);
          }}
          onMouseLeave={() => {
            dragRef.current = null;
            setIsDragging(false);
          }}
          onWheel={(event) => {
            event.preventDefault();
            setZoom((prev) => clamp(prev - event.deltaY * 0.001, 0.72, 1.7));
          }}
        >
          <div className="pointer-events-none relative h-full w-full overflow-hidden rounded-[2rem]">
            <div
              className="absolute left-1/2 top-1/2"
              style={{
                transformStyle: "preserve-3d",
                transform: `translate3d(-50%, -36%, 0) rotateX(${rotation.x}deg) rotateY(${rotation.y}deg) scale(${zoom})`,
                transition: isDragging ? "none" : "transform 90ms linear",
              }}
            >
              {blocks.map((block) => (
                <div
                  key={block.id}
                  className="absolute"
                  style={{
                    transformStyle: "preserve-3d",
                    transform: `translate3d(${block.x}px, ${block.y}px, ${block.z}px)`,
                  }}
                >
                  <span
                    className="absolute block"
                    style={{
                      width: SIZE,
                      height: SIZE,
                      background: block.top,
                      transform: `translate3d(${-SIZE / 2}px, ${-SIZE / 2}px, ${SIZE / 2}px) rotateX(0deg)`,
                    }}
                  />
                  <span
                    className="absolute block"
                    style={{
                      width: SIZE,
                      height: SIZE,
                      background: block.left,
                      transform: `translate3d(${-SIZE / 2}px, ${-SIZE / 2}px, 0) rotateY(-90deg)`,
                      transformOrigin: "left center",
                    }}
                  />
                  <span
                    className="absolute block"
                    style={{
                      width: SIZE,
                      height: SIZE,
                      background: block.right,
                      transform: `translate3d(${SIZE / 2}px, ${-SIZE / 2}px, 0) rotateY(90deg)`,
                      transformOrigin: "right center",
                    }}
                  />
                </div>
              ))}
              {blocks.length === 0 ? (
                <div className="absolute left-1/2 top-1/2 -translate-x-1/2 rounded-xl border border-amber-200/40 bg-black/45 px-4 py-2 text-sm text-amber-100">
                  没有可渲染的地形数据
                </div>
              ) : null}
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
