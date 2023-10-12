package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"github.com/hashicorp/go-retryablehttp"
	"github.com/labstack/gommon/log"
	"io/ioutil"
	"math/rand"
	"net/http"
	"os"
	"regexp"
	"strings"
	"sync"
	"time"
)

// NOTE: modules do not behave when you deal with multiple projects under the same root, had to put all the logic under main.go file

const devicesCollectionKey = "devices-test"
const locationsCollectionKey = "locations-test"
const usersCollectionKey = "users-test"
const baseUrlKey = "baseUrl"
const collectionKey = "collection"
const methodKey = "method"
const numOfCallsKey = "numOfCalls"

const deviceIdsFilePath = "ids"

const nanoToMilliDivisor = 1000000

var allowedHttpMethods = []string{"POST", "GET"}
var acceptedStatusCodes = []int{http.StatusAccepted, http.StatusOK, http.StatusNoContent}
var deviceIds = []string{"606405c10f25", "606405c11096", "606405c117a8", "74e1821171a2", "74e182117725", "74e182118881",
	"74e182167461", "74e182167758", "74e1821697cc", "8cc7aa027840", "a810872bd801", "c8df845a335e", "f045da2cc1ed",
	"f4844c63af9c", "f87aef010146",
}
var collectionIds = map[string][]string{
	devicesCollectionKey:   deviceIds,
	locationsCollectionKey: {},
	usersCollectionKey:     {},
}
var defaultSettings = map[string]string{
	baseUrlKey:    "http://localhost:3000",
	collectionKey: devicesCollectionKey,
	methodKey:     "POST",
	numOfCallsKey: "5",
}

func main() {
	help := flag.Bool("h", false, "-h if a help flag to display command options")
	baseUrl := flag.String("bu", "http://localhost:3000", "-bu is a base url flag, e.g. -bu=http://localhost:3000")
	collection := flag.String("c", devicesCollectionKey, "-c is the collection flag, e.g. -c=users-test")
	method := flag.String("m", "POST", "-m is the http method flag, e.g. -m=GET")
	numOfCalls := flag.Int("n", 5, "-n is the number of http calls to make, e.g. -n=1000")
	random := flag.Bool("r", false, "-r is the randomization for device ids, enabling it will randomly choose the device id from the hardcoded list")

	flag.Parse()

	if *help {
		flag.Usage()
	} else {
		dIds, err := readLines(deviceIdsFilePath)
		if err != nil {
			println("failed to pull device ids from file %s", deviceIdsFilePath)
		} else {
			collectionIds[devicesCollectionKey] = dIds
			println(fmt.Sprintf("using device ids from test ids file %s", strings.Join(dIds, ",")))
		}
		runTest(*baseUrl, *collection, *method, *numOfCalls, *random)
	}
}

func runTest(baseUrlStr string, collectionStr string, methodStr string, numOfCalls int, random bool) {
	var err error
	httpsRegex, err := compileRegexes()
	if err != nil {
		log.Errorf("failed to compile https/http regex, err: %v", err)
	}

	baseUrl := defaultSettings[baseUrlKey]
	if isUrlValid(httpsRegex, baseUrlStr) {
		baseUrl = baseUrlStr
	} else {
		println(fmt.Sprintf("base url provided %s is not vaid, applying default %s", baseUrl,
			defaultSettings[baseUrlKey]))
	}

	collection := collectionStr
	if _, ok := collectionIds[collectionStr]; !ok {
		println(fmt.Sprintf("collection %s is not allowed, applying default %s", collection, devicesCollectionKey))
		collection = devicesCollectionKey
	}

	method := defaultSettings[methodKey]
	methodStrTemp := strings.ToUpper(methodStr)
	if isAllowedStr(methodStrTemp, allowedHttpMethods) {
		method = methodStrTemp
	} else {
		println(fmt.Sprintf("method %s is not allowed, applying default %s", methodStrTemp, defaultSettings[methodKey]))
	}

	println(fmt.Sprintf("test is going to be performed with %s baseUrl, %s collection, %s method, %d number of calls",
		baseUrl, collection, method, numOfCalls))

	httpClient := initializeFloHttpClient()

	timeStart := time.Now()
	wg := &sync.WaitGroup{}
	initiateHttpRequests(httpClient, random, numOfCalls, baseUrl, method, collection, collectionIds, acceptedStatusCodes, wg)
	wg.Wait()
	timeStop := time.Now()
	diffT := timeStop.Sub(timeStart)
	diffTms := diffT.Nanoseconds() / nanoToMilliDivisor

	println(fmt.Sprintf("for %d parallel https calls it took %dms", numOfCalls, diffTms))

	res, err := MakeHttpRequest(httpClient, baseUrl, "GET", "/v1/stats", "")
	if err != nil {
		println("FAILED to make GET /stats request")
	}
	if res != nil {
		if res.StatusCode == http.StatusOK {
			body := res.Body

			bodyBytes, err := ioutil.ReadAll(body)
			if err != nil {
				println("FAILED to get response body of /stats request")
			}
			bodyString := string(bodyBytes)

			println("collected firewriter stats: %s", bodyString)
		}
	}
}

func readLines(path string) ([]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		str := scanner.Text()
		if str != "" {
			lines = append(lines, scanner.Text())
		}
	}
	return lines, scanner.Err()
}

func initiateHttpRequests(httpClient *retryablehttp.Client, random bool, numOfCalls int, baseUrl string, method string,
	collection string, collectionIdsMap map[string][]string, acceptedHttpCodes []int, wg *sync.WaitGroup) {

	seriesIds := collectionIdsMap[collection]
	if numOfCalls > len(seriesIds) {
		var tempSeriesIds = []string{}
		for i := 0; i < numOfCalls; i++ {
			for j := 0; j < len(collectionIds) && len(tempSeriesIds) <= numOfCalls; j++ {
				tempSeriesIds = append(tempSeriesIds, seriesIds[i])
			}
		}
		seriesIds = tempSeriesIds
	}

	for i := 0; i < numOfCalls; i++ {
		wg.Add(1)
		id := seriesIds[i]
		if random {
			collectionIdInx := rand.Intn(len(seriesIds))
			id = seriesIds[collectionIdInx]
		}
		collectionPartialPath := getCollectionPath(collection)
		relativePath := fmt.Sprintf("/v1/firestore/%s/%s", collectionPartialPath, id)
		partialDataFlag := false
		// half of the requests are with partial data
		if i%2 == 0 {
			partialDataFlag = true
		}
		generatedBody, err := generateBody(collection, id, partialDataFlag)
		if err != nil {
			println(fmt.Sprintf("FAILED to generate request body, err: %v", err))
		} else {
			go func() {
				res, err := MakeHttpRequest(httpClient, baseUrl, method, relativePath, generatedBody)
				if err != nil {
					println("ERROR has occurred while while making an http %s request to %s with body %s", method,
						fmt.Sprintf("%s/%s", baseUrl, relativePath), generatedBody)
				} else {
					if !isAllowedInt(res.StatusCode, acceptedHttpCodes) {
						println("http %s request to %s with body %s FAILED with status code %d", method,
							fmt.Sprintf("%s/%s", baseUrl, relativePath), generatedBody, res.StatusCode)
					}
				}
				wg.Done()
			}()
		}
	}
}

func generateBody(collection string, id string, allDataFlag bool) (string, error) {
	body := ""
	switch collection {
	case devicesCollectionKey:
		var data map[string]interface{}
		if allDataFlag {
			data = GetAllDeviceRealTime(id)
		} else {
			data = GetRandomlyPartialDeviceRealTime(id)
		}
		d, err := json.Marshal(data)
		if err != nil {
			return body, err
		} else {
			body = string(d)
		}
	default:
		println(fmt.Sprintf("collection %s is not supported", collection))
	}
	return body, nil
}

func isAllowedStr(v string, allowedValues []string) bool {
	for _, m := range allowedValues {
		if v == m {
			return true
		}
	}
	return false
}

func isAllowedInt(v int, allowedValues []int) bool {
	for _, m := range allowedValues {
		if v == m {
			return true
		}
	}
	return false
}

func isUrlValid(httpsRegex *regexp.Regexp, str string) bool {
	return httpsRegex.MatchString(str)
}

func getCollectionPath(collection string) string {
	c := collection
	if strings.Contains(c, "-") {
		cSlice := strings.Split(c, "-")
		c = cSlice[0]
	}
	return c
}

// compileRegexes compiles regexes
func compileRegexes() (*regexp.Regexp, error) {
	regexHttpsPattern := "^https?://"
	httpsRegex, err := regexp.Compile(regexHttpsPattern)
	if err != nil {
		return httpsRegex, nil
	}
	return httpsRegex, nil
}

func GetAllDeviceRealTime(deviceId string) map[string]interface{} {
	result := make(map[string]interface{})
	result["deviceId"] = deviceId
	result["connectivity"] = map[string]int{
		"rssi": generateRssiValue(),
	}
	result["healthTest"] = map[string]string{
		"status": generateHeatlhStatusValue(),
	}
	result["installStatus"] = map[string]bool{
		"isInstalled": generateBool(),
	}
	result["isConnected"] = generateBool()
	result["updated"] = getNowTs()
	result["systemMode"] = map[string]string{
		"lastKnown": generateSystemModeValue(),
	}
	result["telemetry"] = map[string]map[string]interface{}{
		"current": {
			"gpm":     randFloats(5, 30),
			"psi":     randFloats(5, 30),
			"tempF":   randFloats(30, 120),
			"updated": getNowTs(),
		},
	}

	result["valve"] = map[string]string{
		"lastKnown": generateValveStateValue(),
	}

	result["waterConsumption"] = map[string]interface{}{
		"estimateLastUpdated": getNowTs(),
		"estimateToday":       randFloats(1000, 8000),
	}
	return result
}

func GetRandomlyPartialDeviceRealTime(deviceId string) map[string]interface{} {
	result := make(map[string]interface{})
	deviceKeys := []string{"connectivity", "healthTest", "installStatus", "isConnected", "systemMode", "telemetry",
		"valve", "waterConsumption"}
	resultTemp := GetAllDeviceRealTime(deviceId)
	result["deviceId"] = resultTemp["deviceId"]
	indx := rand.Intn(len(deviceKeys))
	key := deviceKeys[indx]
	if key == "isConnected" {
		result["updated"] = getNowTs()
	}
	result[key] = resultTemp[key]
	return result
}

func randFloats(min, max float64) float64 {
	res := make([]float64, 100)
	for i := range res {
		res[i] = min + rand.Float64()*(max-min)
	}
	indx := rand.Intn(len(res))
	return res[indx]
}

func generateRssiValue() int {
	values := []int{10, 20, 30, 40, 50, 60, 70, 80, 90, -10, -20, -30, -40, -50, -60, -70, -80, -90}
	indx := rand.Intn(len(values))
	return values[indx]
}

func generateHeatlhStatusValue() string {
	values := []string{"cancelled", "failed", "passed", "postponed"}
	indx := rand.Intn(len(values))
	return values[indx]
}

func generateBool() bool {
	values := []bool{true, false}
	indx := rand.Intn(len(values))
	return values[indx]
}

func generateSystemModeValue() string {
	values := []string{"home", "away", "unknown", "sleep"}
	indx := rand.Intn(len(values))
	return values[indx]
}

func generateValveStateValue() string {
	values := []string{"unknown", "broken", "inTransition", "closed", "open"}
	indx := rand.Intn(len(values))
	return values[indx]
}

func getNowTs() string {
	t := time.Now().UTC()
	return t.Format(time.RFC3339)
}

func initializeFloHttpClient() *retryablehttp.Client {
	httpClient := retryablehttp.NewClient()
	httpClient.RetryWaitMin = time.Duration(200) * time.Millisecond
	httpClient.RetryWaitMax = time.Duration(300) * time.Millisecond
	httpClient.RetryMax = 3
	httpClient.Backoff = retryablehttp.LinearJitterBackoff
	return httpClient
}

func MakeHttpRequest(httpClient *retryablehttp.Client, baseUrl string, method string, endpointRelativePath string,
	body string) (res *http.Response, err error) {

	url := fmt.Sprintf("%s%s", baseUrl, endpointRelativePath)
	req, err := retryablehttp.NewRequest(method, url, strings.NewReader(body))
	if err != nil {
		return nil, err
	}

	req.Header.Add("content-type", "application/json")

	res, err = httpClient.Do(req)
	if err != nil {
		statusCode := 0
		if res != nil {
			statusCode = res.StatusCode
		}
		log.Errorf("failed http %s request to %s with status %d, err %v", method, url, statusCode, err)
	}

	return res, err
}
