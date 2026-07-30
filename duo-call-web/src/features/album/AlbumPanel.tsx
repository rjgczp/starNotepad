import { Icon } from "@iconify/react";
import { displayNameForSlot } from "../../preferences";
import { mediaUrl, type AlbumItem, type Identity } from "../../domain";

export function AlbumPanel({
  albums,
  page,
  pages,
  total,
  uploading,
  uploadInput,
  onUpload,
  onDelete,
  onPage,
  identities,
  me,
}: {
  albums: AlbumItem[];
  page: number;
  pages: number;
  total: number;
  uploading: boolean;
  uploadInput: React.RefObject<HTMLInputElement | null>;
  onUpload: (file: File) => void;
  onDelete: (id: number) => void;
  onPage: (page: number) => void;
  identities: Identity[];
  me: number;
}) {
  return (
    <main className="album-page">
      <header className="album-page-heading">
        <div>
          <p>OUR LITTLE MEMORIES</p>
          <h1>我们的相册</h1>
          <small>共 {total} 张照片，每页 20 张。</small>
        </div>
        <div>
          <input
            ref={uploadInput}
            hidden
            type="file"
            accept="image/*"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) onUpload(file);
              e.target.value = "";
            }}
          />
          <button
            className="upload-album"
            disabled={uploading}
            onClick={() => uploadInput.current?.click()}
          >
            <Icon icon="solar:gallery-add-bold" />
            {uploading ? "正在上传…" : "添加照片"}
          </button>
        </div>
      </header>
      <section className="album-grid">
        {albums.length
          ? albums.map((album) => (
            <article className="album-photo" key={album.ID}>
              <img src={mediaUrl(album.imageUrl)} alt={`相册照片 ${album.ID}`} />
              <div>
                <span>
                  {displayNameForSlot(identities, album.uploaderSlot, me)} ·{" "}
                  {new Date(album.uploadedAt).toLocaleDateString("zh-CN")}
                </span>
                <button
                  onClick={() =>
                    onDelete(album.ID)}
                  title="删除照片"
                >
                  <Icon icon="solar:trash-bin-trash-bold" />
                </button>
              </div>
            </article>
          ))
          : (
            <div className="album-empty">
              <Icon icon="solar:gallery-add-bold-duotone" />
              <strong>第一张照片，等你们一起放进来。</strong>
              <span>支持 JPG、PNG、GIF、WebP，单张不超过 10MB。</span>
            </div>
          )}
      </section>
      {pages > 1 && (
        <nav className="album-pagination" aria-label="相册分页">
          <button disabled={page === 1} onClick={() => onPage(page - 1)}>
            <Icon icon="solar:arrow-left-bold" />
          </button>
          <span>第 {page} / {pages} 页</span>
          <button disabled={page === pages} onClick={() => onPage(page + 1)}>
            <Icon icon="solar:arrow-right-bold" />
          </button>
        </nav>
      )}
    </main>
  );
}
