import { lazy, StrictMode, Suspense } from "react";
import { createRoot } from "react-dom/client";
import "./styles/index.css";
import { App } from "./App";
import { ImageViewerProvider } from "./components/ImageViewer";

const QixiStory = lazy(() =>
  import("./features/qixi/QixiStory").then((module) => ({ default: module.QixiStory }))
);

const normalizedPath = window.location.pathname.replace(/\/+$/, "") || "/";
const content = normalizedPath === "/qx"
  ? (
    <Suspense fallback={<div style={{ position: "fixed", inset: 0, background: "#250d19" }} />}>
      <QixiStory />
    </Suspense>
  )
  : (
    <ImageViewerProvider>
      <App />
    </ImageViewerProvider>
  );

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    {content}
  </StrictMode>,
);
