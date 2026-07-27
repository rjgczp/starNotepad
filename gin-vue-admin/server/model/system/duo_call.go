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
