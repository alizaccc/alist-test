package halalcloudopen

import (
	"github.com/alist-org/alist/v3/internal/driver"
	"github.com/alist-org/alist/v3/internal/model"
	sdkClient "github.com/halalcloud/golang-sdk-lite/halalcloud/apiclient"
	sdkUser "github.com/halalcloud/golang-sdk-lite/halalcloud/services/user"
	sdkUserFile "github.com/halalcloud/golang-sdk-lite/halalcloud/services/userfile"
)

type HalalCloudOpen struct {
	*halalCommon
	model.Storage
	Addition
	sdkClient          *sdkClient.Client
	sdkUserFileService *sdkUserFile.UserFileService
	sdkUserService     *sdkUser.UserService
	uploadThread       int
}

func (d *HalalCloudOpen) Config() driver.Config {
	return config
}

func (d *HalalCloudOpen) GetAddition() driver.Additional {
	return &d.Addition
}

var _ driver.Driver = (*HalalCloudOpen)(nil)
