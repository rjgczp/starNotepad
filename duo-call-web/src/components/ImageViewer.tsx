import { Icon } from "@iconify/react";
import {
  createContext,
  type ImgHTMLAttributes,
  type ReactNode,
  useContext,
  useEffect,
  useState,
} from "react";

type ViewerImage = {
  src: string;
  alt: string;
};

const ImageViewerContext = createContext<
  ((image: ViewerImage) => void) | null
>(null);

function downloadName(src: string) {
  try {
    const name = decodeURIComponent(new URL(src, location.href).pathname)
      .split("/")
      .filter(Boolean)
      .pop();
    if (name?.includes(".")) return name;
  } catch {
    // Fall back to a stable local name below.
  }
  return `love-cottage-${Date.now()}.jpg`;
}

export function ImageViewerProvider({ children }: { children: ReactNode }) {
  const [image, setImage] = useState<ViewerImage | null>(null);
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState("");

  useEffect(() => {
    if (!image) return;
    const close = (event: KeyboardEvent) => {
      if (event.key === "Escape") setImage(null);
    };
    window.addEventListener("keydown", close);
    return () => window.removeEventListener("keydown", close);
  }, [image]);

  const save = async () => {
    if (!image || saving) return;
    setSaving(true);
    setStatus("");
    try {
      const response = await fetch(image.src);
      if (!response.ok) throw new Error("download failed");
      const blobUrl = URL.createObjectURL(await response.blob());
      const anchor = document.createElement("a");
      anchor.href = blobUrl;
      anchor.download = downloadName(image.src);
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      window.setTimeout(() => URL.revokeObjectURL(blobUrl), 1000);
      setStatus("已交给系统保存");
    } catch {
      const anchor = document.createElement("a");
      anchor.href = image.src;
      anchor.download = downloadName(image.src);
      anchor.target = "_blank";
      anchor.rel = "noopener";
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      setStatus("已打开系统图片页；如未自动保存，请长按图片保存");
    } finally {
      setSaving(false);
    }
  };

  return (
    <ImageViewerContext.Provider value={(next) => {
      setStatus("");
      setImage(next);
    }}>
      {children}
      {image && (
        <div className="image-viewer-backdrop" onClick={() => setImage(null)}>
          <section
            className="image-viewer"
            role="dialog"
            aria-modal="true"
            aria-label="图片预览"
            onClick={(event) => event.stopPropagation()}
          >
            <header>
              <span>{image.alt || "图片预览"}</span>
              <button
                type="button"
                onClick={() => setImage(null)}
                aria-label="关闭图片预览"
              >
                <Icon icon="solar:close-circle-bold" />
              </button>
            </header>
            <div className="image-viewer-canvas">
              <img src={image.src} alt={image.alt} />
            </div>
            <footer>
              <small aria-live="polite">{status}</small>
              <button type="button" onClick={() => void save()} disabled={saving}>
                <Icon icon="solar:download-minimalistic-bold" />
                {saving ? "正在保存…" : "保存到本地"}
              </button>
            </footer>
          </section>
        </div>
      )}
    </ImageViewerContext.Provider>
  );
}

export function ZoomableImage({
  src,
  alt = "",
  onClick,
  onKeyDown,
  ...props
}: ImgHTMLAttributes<HTMLImageElement>) {
  const open = useContext(ImageViewerContext);
  return (
    <img
      {...props}
      src={src}
      alt={alt}
      className={`${props.className || ""} zoomable-image`.trim()}
      role="button"
      tabIndex={0}
      onClick={(event) => {
        event.stopPropagation();
        onClick?.(event);
        if (!event.defaultPrevented && src) open?.({ src, alt });
      }}
      onKeyDown={(event) => {
        onKeyDown?.(event);
        if (
          !event.defaultPrevented &&
          src &&
          (event.key === "Enter" || event.key === " ")
        ) {
          event.preventDefault();
          open?.({ src, alt });
        }
      }}
    />
  );
}
