import { useEffect, useState } from "react";
import {
  messageSide,
  profileInitial,
  resolveProfileAvatar,
} from "../preferences";
import { mediaUrl, type Identity, type Message } from "../domain";
import { ZoomableImage } from "./ImageViewer";

export function ProfileAvatar({
  identity,
  src,
  className = "",
}: {
  identity?: Pick<Identity, "displayName" | "avatarUrl">;
  src?: string;
  className?: string;
}) {
  const image = mediaUrl(resolveProfileAvatar(src, identity?.avatarUrl));
  const [failed, setFailed] = useState(false);
  useEffect(() => setFailed(false), [image]);
  return (
    <span className={`profile-avatar ${className}`}>
      {image && !failed
        ? (
          <ZoomableImage
            src={image}
            alt={`${identity?.displayName || "成员"}的头像`}
            onError={() => setFailed(true)}
          />
        )
        : <b>{profileInitial(identity?.displayName || "")}</b>}
    </span>
  );
}

export function ChatMessage({
  message,
  me,
  identities,
  onImageLoad,
}: {
  message: Message;
  me: number;
  identities: Identity[];
  onImageLoad: () => void;
}) {
  const identity = identities.find((item) => item.slot === message.senderSlot);
  const side = messageSide(message.senderSlot, me);
  return (
    <article className={`message-row ${side}`}>
      <ProfileAvatar identity={identity} />
      <div className="message">
        {message.kind === "image"
          ? <ZoomableImage src={mediaUrl(message.imageUrl)} alt="聊天图片" onLoad={onImageLoad} />
          : message.content}
      </div>
    </article>
  );
}
