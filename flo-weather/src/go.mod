module main

go 1.13

require (
	github.com/aws/aws-sdk-go v1.25.19
	github.com/confluentinc/confluent-kafka-go v1.3.0
	github.com/go-errors/errors v1.0.2
	github.com/go-playground/validator/v10 v10.2.0
	github.com/go-redis/redis v6.15.6+incompatible
	github.com/google/go-querystring v1.0.0
	github.com/google/uuid v1.1.1 // indirect
	github.com/gorilla/mux v1.7.3
	github.com/gorilla/schema v1.1.0
	github.com/instana/go-sensor v1.5.0
	github.com/lib/pq v1.2.0
	github.com/mmcloughlin/geohash v0.9.0
	github.com/onsi/ginkgo v1.10.2 // indirect
	github.com/onsi/gomega v1.7.0 // indirect
	github.com/opentracing/opentracing-go v1.1.0
	github.com/pkg/errors v0.8.1
	github.com/sergi/go-diff v1.1.0 // indirect
	github.com/spaolacci/murmur3 v1.1.0
	github.com/swaggo/http-swagger v0.0.0-20191217015043-dfd2c09b9590
	gitlab.com/flotechnologies/flo-weather/docs v0.0.0
	golang.org/x/sync v0.0.0-20190423024810-112230192c58
	golang.org/x/time v0.0.0-20191024005414-555d28b269f0 // indirect
	googlemaps.github.io/maps v0.0.0-20200130222743-aef6b08443c7
)

replace gitlab.com/flotechnologies/flo-weather/docs v0.0.0 => ./docs
