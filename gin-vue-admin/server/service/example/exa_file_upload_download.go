package example

import (
	"archive/zip"
	"errors"
	"io"
	"io/fs"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/example"
	"github.com/flipped-aurora/gin-vue-admin/server/model/example/request"
	"github.com/flipped-aurora/gin-vue-admin/server/utils/upload"
	"gorm.io/gorm"
)

func unzipToDir(zipPath, targetDir string) error {
	r, err := zip.OpenReader(zipPath)
	if err != nil {
		return err
	}
	defer r.Close()

	if err = os.MkdirAll(targetDir, os.ModePerm); err != nil {
		return err
	}

	cleanTarget := filepath.Clean(targetDir)
	for _, f := range r.File {
		dstPath := filepath.Join(targetDir, f.Name)
		cleanDst := filepath.Clean(dstPath)
		if !strings.HasPrefix(cleanDst, cleanTarget+string(os.PathSeparator)) && cleanDst != cleanTarget {
			return errors.New("invalid zip file path")
		}

		if f.FileInfo().IsDir() {
			if err = os.MkdirAll(cleanDst, os.ModePerm); err != nil {
				return err
			}
			continue
		}

		if err = os.MkdirAll(filepath.Dir(cleanDst), os.ModePerm); err != nil {
			return err
		}

		rc, openErr := f.Open()
		if openErr != nil {
			return openErr
		}

		out, createErr := os.OpenFile(cleanDst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, f.Mode())
		if createErr != nil {
			rc.Close()
			return createErr
		}

		_, copyErr := io.Copy(out, rc)
		_ = out.Close()
		_ = rc.Close()
		if copyErr != nil {
			return copyErr
		}
	}

	return nil
}

func detectWorldRootDir(baseDir string) (string, error) {
	cleanBase := filepath.Clean(baseDir)
	if _, err := os.Stat(filepath.Join(cleanBase, "level.dat")); err == nil {
		return cleanBase, nil
	}

	best := ""
	err := filepath.WalkDir(cleanBase, func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil || d.IsDir() {
			return nil
		}
		if !strings.EqualFold(d.Name(), "level.dat") {
			return nil
		}
		candidate := filepath.Clean(filepath.Dir(path))
		if !strings.HasPrefix(candidate, cleanBase+string(os.PathSeparator)) && candidate != cleanBase {
			return nil
		}
		if best == "" || len(candidate) < len(best) {
			best = candidate
		}
		return nil
	})
	if err != nil {
		return "", err
	}
	if best == "" {
		return cleanBase, nil
	}
	return best, nil
}

//@author: [piexlmax](https://github.com/piexlmax)
//@function: Upload
//@description: 创建文件上传记录
//@param: file model.ExaFileUploadAndDownload
//@return: error

func (e *FileUploadAndDownloadService) Upload(file example.ExaFileUploadAndDownload) error {
	return global.GVA_DB.Create(&file).Error
}

//@author: [piexlmax](https://github.com/piexlmax)
//@function: FindFile
//@description: 查询文件记录
//@param: id uint
//@return: model.ExaFileUploadAndDownload, error

func (e *FileUploadAndDownloadService) FindFile(id uint) (example.ExaFileUploadAndDownload, error) {
	var file example.ExaFileUploadAndDownload
	err := global.GVA_DB.Where("id = ?", id).First(&file).Error
	return file, err
}

//@author: [piexlmax](https://github.com/piexlmax)
//@function: DeleteFile
//@description: 删除文件记录
//@param: file model.ExaFileUploadAndDownload
//@return: err error

func (e *FileUploadAndDownloadService) DeleteFile(file example.ExaFileUploadAndDownload) (err error) {
	var fileFromDb example.ExaFileUploadAndDownload
	fileFromDb, err = e.FindFile(file.ID)
	if err != nil {
		return
	}
	oss := upload.NewOss()
	if err = oss.DeleteFile(fileFromDb.Key); err != nil {
		return errors.New("文件删除失败")
	}
	err = global.GVA_DB.Where("id = ?", file.ID).Unscoped().Delete(&file).Error
	return err
}

// EditFileName 编辑文件名或者备注
func (e *FileUploadAndDownloadService) EditFileName(file example.ExaFileUploadAndDownload) (err error) {
	var fileFromDb example.ExaFileUploadAndDownload
	return global.GVA_DB.Where("id = ?", file.ID).First(&fileFromDb).Update("name", file.Name).Error
}

//@author: [piexlmax](https://github.com/piexlmax)
//@function: GetFileRecordInfoList
//@description: 分页获取数据
//@param: info request.ExaAttachmentCategorySearch
//@return: list interface{}, total int64, err error

func (e *FileUploadAndDownloadService) GetFileRecordInfoList(info request.ExaAttachmentCategorySearch) (list []example.ExaFileUploadAndDownload, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
	db := global.GVA_DB.Model(&example.ExaFileUploadAndDownload{})

	if len(info.Keyword) > 0 {
		db = db.Where("name LIKE ?", "%"+info.Keyword+"%")
	}

	if info.ClassId > 0 {
		db = db.Where("class_id = ?", info.ClassId)
	}

	err = db.Count(&total).Error
	if err != nil {
		return
	}
	err = db.Limit(limit).Offset(offset).Order("id desc").Find(&list).Error
	return list, total, err
}

//@author: [piexlmax](https://github.com/piexlmax)
//@function: UploadFile
//@description: 根据配置文件判断是文件上传到本地或者七牛云
//@param: header *multipart.FileHeader, noSave string
//@return: file model.ExaFileUploadAndDownload, err error

func (e *FileUploadAndDownloadService) UploadFile(header *multipart.FileHeader, noSave string, classId int) (file example.ExaFileUploadAndDownload, err error) {
	oss := upload.NewOss()
	filePath, key, uploadErr := oss.UploadFile(header)
	if uploadErr != nil {
		return file, uploadErr
	}

	if global.GVA_CONFIG.System.OssType == "local" && strings.EqualFold(filepath.Ext(header.Filename), ".zip") {
		zipAbsPath := filepath.Join(global.GVA_CONFIG.Local.StorePath, key)
		dirName := strings.TrimSuffix(key, filepath.Ext(key))
		targetDir := filepath.Join(global.GVA_CONFIG.Local.StorePath, dirName)

		if unzipErr := unzipToDir(zipAbsPath, targetDir); unzipErr != nil {
			_ = os.RemoveAll(targetDir)
			return file, unzipErr
		}

		_ = os.Remove(zipAbsPath)
		worldRootDir, detectErr := detectWorldRootDir(targetDir)
		if detectErr != nil {
			return file, detectErr
		}
		relWorldRoot, relErr := filepath.Rel(global.GVA_CONFIG.Local.StorePath, worldRootDir)
		if relErr == nil && relWorldRoot != "." && !strings.HasPrefix(relWorldRoot, "..") {
			filePath = strings.TrimRight(global.GVA_CONFIG.Local.Path, "/") + "/" + filepath.ToSlash(relWorldRoot)
		} else {
			filePath = strings.TrimRight(global.GVA_CONFIG.Local.Path, "/") + "/" + dirName
		}
		key = dirName
	}

	s := strings.Split(header.Filename, ".")
	f := example.ExaFileUploadAndDownload{
		Url:     filePath,
		Name:    header.Filename,
		ClassId: classId,
		Tag:     s[len(s)-1],
		Key:     key,
	}
	if noSave == "0" {
		// 检查是否已存在相同key的记录
		var existingFile example.ExaFileUploadAndDownload
		err = global.GVA_DB.Where(&example.ExaFileUploadAndDownload{Key: key}).First(&existingFile).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return f, e.Upload(f)
		}
		return f, err
	}
	return f, nil
}

//@author: [piexlmax](https://github.com/piexlmax)
//@function: ImportURL
//@description: 导入URL
//@param: file model.ExaFileUploadAndDownload
//@return: error

func (e *FileUploadAndDownloadService) ImportURL(file *[]example.ExaFileUploadAndDownload) error {
	return global.GVA_DB.Create(&file).Error
}
