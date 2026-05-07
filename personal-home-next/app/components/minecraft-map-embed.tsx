"use client";

import { useState, useEffect } from "react";

interface MinecraftMapEmbedProps {
  mapUrl: string;
  worldPath: string;
}

export default function MinecraftMapEmbed({ mapUrl, worldPath }: MinecraftMapEmbedProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    setIsLoading(true);
    setHasError(false);
  }, [mapUrl, worldPath]);

  const handleIframeLoad = () => {
    setIsLoading(false);
  };

  const handleIframeError = () => {
    setIsLoading(false);
    setHasError(true);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-emerald-900 via-teal-800 to-cyan-900">
      <div className="container mx-auto px-4 py-8">
        <div className="bg-black/30 backdrop-blur-sm rounded-2xl border border-emerald-100/20 overflow-hidden">
          {/* Header */}
          <div className="bg-emerald-900/50 backdrop-blur-sm px-6 py-4 border-b border-emerald-100/20">
            <h1 className="text-2xl font-bold text-emerald-100 mb-2">
              Minecraft 地图查看器
            </h1>
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
              <div className="text-emerald-100/75 text-sm">
                <span className="inline-block px-2 py-1 bg-emerald-100/10 rounded-md">
                  当前世界: {worldPath}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                <span className="text-emerald-100/75 text-sm">
                  BlueMap 实时渲染
                </span>
              </div>
            </div>
          </div>

          {/* Map Container */}
          <div className="relative h-[calc(100vh-200px)] bg-black/50">
            {isLoading && (
              <div className="absolute inset-0 flex items-center justify-center bg-black/75 z-10">
                <div className="text-center">
                  <div className="w-8 h-8 border-2 border-emerald-400 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
                  <p className="text-emerald-100">正在加载地图...</p>
                </div>
              </div>
            )}

            {hasError && (
              <div className="absolute inset-0 flex items-center justify-center bg-black/75 z-10">
                <div className="text-center max-w-md mx-auto p-6">
                  <div className="w-12 h-12 bg-red-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
                    <svg className="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <h3 className="text-xl font-semibold text-red-400 mb-2">地图加载失败</h3>
                  <p className="text-emerald-100/75 mb-4">
                    无法连接到 BlueMap 服务。请确保 BlueMap 服务正在运行，并且地图 URL 配置正确。
                  </p>
                  <div className="bg-emerald-900/20 rounded-lg p-3 text-left">
                    <p className="text-xs text-emerald-100/60 mb-1">地图 URL:</p>
                    <p className="text-xs text-emerald-100 font-mono break-all">{mapUrl}</p>
                  </div>
                </div>
              </div>
            )}

            <iframe
              src={mapUrl}
              className={`w-full h-full border-0 ${isLoading ? 'opacity-0' : 'opacity-100'} transition-opacity duration-300`}
              onLoad={handleIframeLoad}
              onError={handleIframeError}
              allowFullScreen
              title="Minecraft 地图"
            />
          </div>

          {/* Footer */}
          <div className="bg-emerald-900/50 backdrop-blur-sm px-6 py-3 border-t border-emerald-100/20">
            <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
              <div className="text-emerald-100/60 text-xs">
                由 BlueMap 提供支持的 3D 世界地图
              </div>
              <div className="flex items-center gap-4">
                <a
                  href={mapUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-emerald-100/60 hover:text-emerald-100 text-xs transition-colors"
                >
                  在新窗口打开
                </a>
                <button
                  onClick={() => window.location.reload()}
                  className="text-emerald-100/60 hover:text-emerald-100 text-xs transition-colors"
                >
                  刷新页面
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
