module main

go 1.13

require (
	github.com/aws/aws-sdk-go v1.25.19
	github.com/confluentinc/confluent-kafka-go v1.3.0
	github.com/gin-gonic/gin v1.4.0
	github.com/go-errors/errors v1.0.2
	github.com/go-playground/validator/v10 v10.3.0
	github.com/go-redis/redis v6.15.6+incompatible
	github.com/gocarina/gocsv v0.0.0-20200330101823-46266ca37bd3
	github.com/golang/mock v1.3.1 // indirect
	github.com/google/go-cmp v0.4.0 // indirect
	github.com/google/uuid v1.1.2
	github.com/gorilla/schema v1.1.0
	github.com/instana/go-sensor v1.5.0
	github.com/klauspost/compress v1.9.7 // indirect
	github.com/lib/pq v1.2.0
	github.com/onsi/ginkgo v1.10.2 // indirect
	github.com/onsi/gomega v1.7.0 // indirect
	github.com/opentracing/opentracing-go v1.1.0
	github.com/pkg/errors v0.8.1
	github.com/spaolacci/murmur3 v1.1.0
	github.com/stretchr/testify v1.4.0
	github.com/swaggo/files v0.0.0-20190704085106-630677cd5c14
	github.com/swaggo/gin-swagger v1.2.0
	github.com/xitongsys/parquet-go v1.5.0
	github.com/xitongsys/parquet-go-source v0.0.0-20191104003508-ecfa341356a6
	gitlab.com/flotechnologies/flo-batch-telemetry/docs v0.0.0
	golang.org/x/sync v0.0.0-20190423024810-112230192c58
	golang.org/x/sys v0.0.0-20190813064441-fde4db37ae7a // indirect
)

replace gitlab.com/flotechnologies/flo-batch-telemetry/docs v0.0.0 => ./docs
