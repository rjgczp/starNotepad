import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./styles/index.css";
import { App } from "./App";
import { ImageViewerProvider } from "./components/ImageViewer";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <ImageViewerProvider>
      <App />
    </ImageViewerProvider>
  </StrictMode>,
);
