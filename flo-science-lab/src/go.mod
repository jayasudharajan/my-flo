module main

go 1.13

require (
	github.com/aws/aws-sdk-go v1.25.19
	github.com/blang/semver v3.5.1+incompatible
	github.com/confluentinc/confluent-kafka-go v1.3.0
	github.com/go-redis/redis v6.15.6+incompatible
	github.com/google/uuid v1.1.1
	github.com/gorilla/mux v1.7.3
	github.com/instana/go-sensor v1.5.0
	github.com/lib/pq v1.2.0
	github.com/onsi/ginkgo v1.10.2 // indirect
	github.com/onsi/gomega v1.7.0 // indirect
	github.com/opentracing/opentracing-go v1.1.0
	github.com/robfig/cron/v3 v3.0.1
	github.com/stretchr/testify v1.4.0 // indirect
	github.com/swaggo/http-swagger v0.0.0-20191217015043-dfd2c09b9590
	gitlab.com/flotechnologies/flo-science-lab/docs v0.0.0
	gitlab.com/flotechnologies/flo-science-lab/ical v0.0.0
	golang.org/x/sys v0.0.0-20190813064441-fde4db37ae7a // indirect
)

replace (
	gitlab.com/flotechnologies/flo-science-lab/docs v0.0.0 => ./docs
	gitlab.com/flotechnologies/flo-science-lab/ical v0.0.0 => ./ical
)
