package halalcloudopen

import (
	"context"
	"strconv"
	"time"

	"github.com/alist-org/alist/v3/internal/model"
	sdkUserFile "github.com/halalcloud/golang-sdk-lite/halalcloud/services/userfile"
)

func (d *HalalCloudOpen) getLink(ctx context.Context, file model.Obj, args model.LinkArgs) (*model.Link, error) {
	if args.Redirect {
		// return nil, model.ErrUnsupported
		fid := file.GetID()
		fpath := file.GetPath()
		if fid != "" {
			fpath = ""
		}
		fi, err := d.sdkUserFileService.GetDirectDownloadAddress(ctx, &sdkUserFile.DirectDownloadRequest{
			Identity: fid,
			Path:     fpath,
		})
		if err != nil {
			return nil, err
		}
		expireAt := fi.ExpireAt
		duration := time.Until(time.UnixMilli(expireAt))
		return &model.Link{
			URL:        fi.DownloadAddress,
			Expiration: &duration,
		}, nil
	}
	result, err := d.sdkUserFileService.ParseFileSlice(ctx, &sdkUserFile.File{
		Identity: file.GetID(),
		Path:     file.GetPath(),
	})
	if err != nil {
		return nil, err
	}

	var addressDuration int64

	nodesNumber := len(result.RawNodes)
	nodesIndex := nodesNumber - 1
	startIndex, endIndex := 0, nodesIndex
	for nodesIndex >= 0 {
		if nodesIndex >= 200 {
			endIndex = 200
		} else {
			endIndex = nodesNumber
		}
		for ; endIndex <= nodesNumber; endIndex += 200 {
			if endIndex == 0 {
				endIndex = 1
			}
			sliceAddress, err := d.sdkUserFileService.GetSliceDownloadAddress(ctx, &sdkUserFile.SliceDownloadAddressRequest{
				Identity: result.RawNodes[startIndex:endIndex],
				Version:  1,
			})
			if err != nil {
				return nil, err
			}
			addressDuration, _ = strconv.ParseInt(sliceAddress.ExpireAt, 10, 64)
			// 注意：这里删除了多余的 fileAddrs 变量
			startIndex = endIndex
			nodesIndex -= 200
		}

	}

	// 注意：这里删除了 size, chunks 和 resultRangeReader 这几个废弃变量

	var duration time.Duration
	if addressDuration != 0 {
		duration = time.Until(time.UnixMilli(addressDuration))
	} else {
		duration = time.Until(time.Now().Add(time.Hour))
	}

	return &model.Link{
		Expiration: &duration,
	}, nil
}
