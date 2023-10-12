package main

import (
	"archive/tar"
	"bufio"
	"bytes"
	"compress/bzip2"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"strings"
	"time"
)

type ModelManifestInfo struct {
	MacAddress   string
	AppVersion   string
	ModelVersion string
	MinFwVersion string
}

// Downloads a file from HTTP source into a byte array
func downloadIntoArray(macAddress string, url string) ([]byte, error) {

	start := time.Now()

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, logError("downloadIntoArray: request error. %v %v", macAddress, err.Error())
	}

	c := http.Client{}

	//resp, err := c.Do(req)
	resp, err := c.Do(req)
	if err != nil {
		return nil, logError("downloadIntoArray: %v %v %v", macAddress, url, err.Error())
	}
	if resp.Body == nil {
		return nil, logError("downloadIntoArray: body is nil %v %v", macAddress, url)
	}
	defer resp.Body.Close()

	x, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, logError("downloadIntoArray: error reading body %v %v %v", macAddress, url, err.Error())
	}

	if len(x) == 0 {
		return nil, logError("downloadIntoArray: empty file %v %v", macAddress, url)
	}

	contextType := strings.ToLower(resp.Header.Get("Content-Type"))
	if strings.Contains(contextType, "text") || strings.Contains(contextType, "html") {
		return nil, logError("downloadIntoArray: data appears to be TEXT or HTML, expecting binary")
	}

	logDebug("downloadIntoArray: downloaded model in %.2f sec(s) %v %v", time.Now().Sub(start).Seconds(), macAddress, url)

	return x, nil
}

// Extracts manifest file's information.
// Assumption: fileData is a BZIP2 compressed TAR file with a 'manifest.txt' text file in root folder
func parseManifestFromTarBzip2(fileData []byte) (*ModelManifestInfo, error) {
	if len(fileData) < 3 {
		return nil, logError("parseManifestFromTarBzip2: file appears incomplete")
	}

	// Validate correct file ( GZIP2 )
	// BZh = HEX: 42 5A  68	 	DEC: 66 90 104
	if fileData[0] != 66 || fileData[1] != 90 || fileData[2] != 104 {
		return nil, logError("parseManifestFromTarBzip2: file type unknown. Expecting BZIP2 source.")
	}

	buf := bytes.NewReader(fileData)
	comp := bzip2.NewReader(buf)

	tarContents := make([]byte, 0)
	tarBuf := bytes.NewBuffer(tarContents)

	// create a scanner
	s := bufio.NewScanner(tarBuf)

	// scan the file! until Scan() returns "EOF", print out each line
	for s.Scan() {
		tarBuf.Write(s.Bytes())
	}

	tr := tar.NewReader(comp)
	for {
		hdr, err := tr.Next()
		if err == io.EOF {
			break // End of archive
		}
		if err != nil {
			return nil, logError("parseManifestFromTarBzip2: %v", err.Error())
		}
		if hdr == nil {
			continue
		}

		if !hdr.FileInfo().IsDir() {
			cleanFile := strings.ToLower(strings.TrimSpace(hdr.Name))

			if strings.HasSuffix(cleanFile, "manifest.txt") {
				data, err := ioutil.ReadAll(tr)
				if err != nil {
					return nil, logError("parseManifestFromTarBzip2: error reading manifest. %v", err.Error())
				}
				if len(data) == 0 {
					return nil, logError("parseManifestFromTarBzip2: manifest.txt is empty")
				}

				manifestText := string(data)
				parts := strings.Split(manifestText, "\n")

				rv := new(ModelManifestInfo)
				for _, p := range parts {
					if len(p) < 3 {
						continue
					}
					kv := strings.Split(p, ":")
					if len(kv) < 2 {
						continue
					}
					pkey := strings.ToLower(strings.TrimSpace(kv[0]))

					switch pkey {
					case "deviceid":
						rv.MacAddress = strings.Join(kv[1:], ":")
					case "manifest_app_version":
						rv.AppVersion = strings.Join(kv[1:], ":")
					case "manifest_model_version":
						rv.ModelVersion = strings.Join(kv[1:], ":")
					case "min_fw_version":
						rv.MinFwVersion = strings.Join(kv[1:], ":")
					}
				}
				return rv, nil
			}
		}
	}

	return nil, logError("parseManifestFromTarBzip2: manifest.txt not found")
}

func uploadFloSenseModelS3(item *FloSenseApiModel, fileData []byte) (error, string) {
	if item == nil {
		return logError("uploadFloSenseModelS3: nil model"), ""
	}

	// Upload to S3
	key := fmt.Sprintf("models/%v-%v.model", item.MacAddress, item.Id)
	err := _s3.UploadPublicReadFile(_modelBucketName, key, fileData)
	if err != nil {
		updateModelRecordState(item.Id, MODEL_STATUS_ERROR, "s3 error")
		return logError("uploadFloSenseModelS3: unable to upload to s3. %v %v %v %v %v", item.MacAddress, item.Id, _modelBucketName, key, err.Error()), ""
	}

	// Update the record
	dlUrl := _modelUrlPrefix + "/" + key
	_, err = _pgCn.ExecNonQuery("UPDATE flosense_models SET state=$2, download_url=$3, updated=$4, state_message='' WHERE id=$1",
		item.Id,
		MODEL_STATUS_READY,
		dlUrl,
		time.Now().UTC().Truncate(time.Second))

	if err != nil {
		return logError("uploadFloSenseModelS3: db error %v %v %v", item.MacAddress, item.Id, err.Error()), ""
	}

	item.DownloadLocation = dlUrl
	logDebug("uploadFloSenseModelS3: success %v %v %v %v", item.MacAddress, item.Id, len(fileData), key)
	return nil, dlUrl
}
