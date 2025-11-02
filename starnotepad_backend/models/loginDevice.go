package models

type LoginDevice struct {
	ID             uint   `json:"id" gorm:"primaryKey"`                              //ID
	UserID         uint   `json:"user_id" gorm:"type:int;not null"`                  //用户ID
	DeviceID       string `json:"device_id" gorm:"type:varchar(255);not null"`       //设备ID
	DeviceName     string `json:"device_name" gorm:"type:varchar(255);not null"`     //设备名称
	DeviceType     string `json:"device_type" gorm:"type:varchar(255);not null"`     //设备类型
	DeviceToken    string `json:"device_token" gorm:"type:varchar(255);not null"`    //设备Token
	DeviceIP       string `json:"device_ip" gorm:"type:varchar(255);not null"`       //设备IP
	DeviceLocation string `json:"device_location" gorm:"type:varchar(255);not null"` //设备位置
}
