package system

import (
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
)

// DuoCallIdentity is one of the two fixed identities allowed into the pair room.
type DuoCallIdentity struct {
	global.GVA_MODEL
	Slot         uint   `json:"slot" gorm:"uniqueIndex;not null"`
	DisplayName  string `json:"displayName" gorm:"size:64;not null"`
	AvatarURL    string `json:"avatarUrl" gorm:"size:1024"`
	EncryptedKey string `json:"-" gorm:"type:text;not null"`
	Enabled      bool   `json:"enabled" gorm:"default:false;index"`
	KeyVersion   uint   `json:"keyVersion" gorm:"default:1"`
	StatusID     *uint  `json:"statusId"`
}

func (DuoCallIdentity) TableName() string { return "duo_call_identities" }

type DuoCallStatus struct {
	global.GVA_MODEL
	Label   string `json:"label" gorm:"size:64;not null"`
	Emoji   string `json:"emoji" gorm:"size:32"`
	Enabled bool   `json:"enabled" gorm:"default:true;index"`
	Sort    int    `json:"sort" gorm:"default:0;index"`
}

func (DuoCallStatus) TableName() string { return "duo_call_statuses" }

type DuoCallMessage struct {
	global.GVA_MODEL
	SenderSlot uint       `json:"senderSlot" gorm:"not null;index"`
	Kind       string     `json:"kind" gorm:"size:16;not null;default:text"` // text or image
	Content    string     `json:"content" gorm:"type:text"`
	ImageURL   string     `json:"imageUrl" gorm:"size:1024"`
	ReadAt     *time.Time `json:"readAt"`
}

func (DuoCallMessage) TableName() string { return "duo_call_messages" }

// DuoCallAlbum keeps pair-only photos separate from chat image messages.
type DuoCallAlbum struct {
	global.GVA_MODEL
	UploaderSlot uint      `json:"uploaderSlot" gorm:"not null;index"`
	ImageURL     string    `json:"imageUrl" gorm:"size:1024;not null"`
	UploadedAt   time.Time `json:"uploadedAt" gorm:"not null;index"`
}

func (DuoCallAlbum) TableName() string { return "duo_call_albums" }

// DuoCallAnniversary is an administrator-managed couple milestone.
type DuoCallAnniversary struct {
	global.GVA_MODEL
	Title   string    `json:"title" gorm:"size:128;not null"`
	Date    time.Time `json:"date" gorm:"not null;index"`
	Enabled bool      `json:"enabled" gorm:"default:true;index"`
	Sort    int       `json:"sort" gorm:"default:0;index"`
}

func (DuoCallAnniversary) TableName() string { return "duo_call_anniversaries" }

// DuoCallNote stores the latest little note shown on the pair home page.
type DuoCallNote struct {
	global.GVA_MODEL
	SenderSlot uint   `json:"senderSlot" gorm:"not null;index"`
	Content    string `json:"content" gorm:"type:text;not null"`
}

func (DuoCallNote) TableName() string { return "duo_call_notes" }

// DuoMissYou records a heart-button signal so an offline partner can receive
// the same moment on their next visit, while an online partner can see it in
// real time over the room WebSocket.
type DuoMissYou struct {
	global.GVA_MODEL
	SenderSlot     uint       `json:"senderSlot" gorm:"not null;index"`
	RecipientSlot  uint       `json:"recipientSlot" gorm:"not null;index"`
	Message        string     `json:"message" gorm:"size:128;not null"`
	AcknowledgedAt *time.Time `json:"acknowledgedAt,omitempty" gorm:"index"`
}

func (DuoMissYou) TableName() string { return "duo_miss_you" }

// DuoAppRelease is a downloadable Love Cottage client release. Releases stay
// private until an administrator publishes them from Gin-Vue-Admin.
type DuoAppRelease struct {
	global.GVA_MODEL
	Platform     string     `json:"platform" gorm:"size:16;not null;uniqueIndex:idx_duo_app_release_platform_version"`
	Version      string     `json:"version" gorm:"size:64;not null;uniqueIndex:idx_duo_app_release_platform_version"`
	DownloadURL  string     `json:"downloadUrl" gorm:"size:2048"`
	ReleaseNotes string     `json:"releaseNotes" gorm:"type:text"`
	ForceUpdate  bool       `json:"forceUpdate" gorm:"default:false"`
	Published    bool       `json:"published" gorm:"default:false;index"`
	PublishedAt  *time.Time `json:"publishedAt" gorm:"index"`
}

func (DuoAppRelease) TableName() string { return "duo_app_releases" }

// DuoGrowthEvent is an immutable, idempotent memory that contributes to the
// shared tree. SourceKey identifies the original action across retries.
type DuoGrowthEvent struct {
	global.GVA_MODEL
	EventType  string    `json:"eventType" gorm:"size:32;not null;index"`
	SourceKey  string    `json:"-" gorm:"size:128;not null;uniqueIndex"`
	SourceID   uint      `json:"sourceId" gorm:"index"`
	Slot       uint      `json:"slot" gorm:"index"`
	Growth     int       `json:"growth" gorm:"not null"`
	Title      string    `json:"title" gorm:"size:128;not null"`
	Summary    string    `json:"summary" gorm:"type:text"`
	ImageURL   string    `json:"imageUrl" gorm:"size:1024"`
	OccurredAt time.Time `json:"occurredAt" gorm:"not null;index"`
}

func (DuoGrowthEvent) TableName() string { return "duo_growth_events" }

// DuoWeeklyMemory stores one shared retrospective per ISO week.
type DuoWeeklyMemory struct {
	global.GVA_MODEL
	WeekKey     string    `json:"weekKey" gorm:"size:10;not null;uniqueIndex"`
	Title       string    `json:"title" gorm:"size:128;not null"`
	Summary     string    `json:"summary" gorm:"type:text;not null"`
	Highlights  string    `json:"-" gorm:"type:text"`
	Source      string    `json:"source" gorm:"size:16;not null"`
	GeneratedAt time.Time `json:"generatedAt" gorm:"not null;index"`
}

func (DuoWeeklyMemory) TableName() string { return "duo_weekly_memories" }
