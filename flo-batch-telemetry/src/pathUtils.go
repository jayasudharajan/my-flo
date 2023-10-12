package main

import (
	"fmt"
	"strings"
	"time"
)

// parseS3ObjectKey returns uri, version and device id from the object key
func parseS3ObjectKey(objectKey string) (uri string, version string, device string) {
	if len(objectKey) >= 12 {
		uri = unEscapeUrlPath(objectKey)
		key := strings.TrimSpace(strings.ToLower(unEscapeUrlPath(objectKey)))
		parts := strings.Split(key, "/")

		if strings.HasPrefix(key, "telemetry-") {
			version, device = parseS3ObjectKeyNotSharded(parts)
		} else if strings.HasPrefix(key, "tlm") {
			version, device = parseS3ObjectKeySharded(parts)
		}
	}
	return
}

func parseS3ObjectKeySharded(parts []string) (version string, device string) {
	prefixFix := parts[0] == "tlm"
	for idx, p := range parts {
		if (!prefixFix && idx == 1) || (prefixFix && idx == 2) {
			version = p
		} else if len(p) >= 21 && strings.HasPrefix(p, "deviceid=") {
			device = p[9:]
		}
	}
	return
}

func parseS3ObjectKeyNotSharded(parts []string) (version string, device string) {
	for _, p := range parts {
		if len(p) >= 10 && strings.HasPrefix(p, "telemetry-") { // looking for: telemetry-v6
			version = p[10:] //auto str concat so p is cleaned up properly
		}
		if len(p) >= 21 && strings.HasPrefix(p, "deviceid=") {
			device = p[9:] //auto str concat so p is cleaned up properly
		}
	}
	return
}

func rebuildBulkFileSource(rs string, date time.Time) (*BulkFileSource, error) {
	bs := BulkFileSource{Date: date, Source: "sqs", BucketName: S3_TELEMETRY_BUCKET}
	bs.AppenderName = rs
	if strings.Contains(rs, "/") {
		bs.SourceUri, bs.SchemaVersion, bs.DeviceId = parseS3ObjectKey(rs)
		bs.Key = calcBulkFileSourceHash(&bs)
		return &bs, nil
	} else { // TODO remove once s3 loader starts using sharded prefixes
		if dots := strings.Split(rs, "."); len(dots) > 3 {
			dps := date.UTC().Format("year=2006/month=01/day=02/hhmm=1504")
			bs.DeviceId = dots[0]
			bs.SchemaVersion = "v" + strings.Join(dots[2:len(dots)-1], ".")
			bs.SourceUri = fmt.Sprintf("telemetry-%v/%v/deviceid=%v/%v", bs.SchemaVersion, dps, bs.DeviceId, rs)
			bs.Key = calcBulkFileSourceHash(&bs)
			return &bs, nil
		}
	}
	return nil, fmt.Errorf("bad date in key | %v", rs)
}

func rebuildBulkFileSourceRaw(rs string) (uri string, version string, device string) {
	if strings.Contains(rs, "/") {
		uri, version, device = parseS3ObjectKey(rs)
	} else { // TODO remove once s3 loader starts using sharded prefixes
		if dots := strings.Split(rs, "."); len(dots) > 3 {
			device = dots[0]
		}
	}
	return
}
