module flotechnologies.com/flo-resource-event/src

go 1.13

require (
	github.com/confluentinc/confluent-kafka-go v1.5.2
	github.com/gin-gonic/gin v1.4.0
	github.com/go-errors/errors v1.1.1
	github.com/go-playground/validator/v10 v10.3.0
	github.com/google/uuid v1.2.0
	github.com/gorilla/schema v1.1.0
	github.com/instana/go-sensor v1.5.0
	github.com/lib/pq v1.2.0
	github.com/opentracing/opentracing-go v1.1.0
	github.com/pkg/errors v0.8.1
	github.com/spaolacci/murmur3 v1.1.0
	github.com/stretchr/testify v1.4.0
	github.com/swaggo/files v0.0.0-20190704085106-630677cd5c14
	github.com/swaggo/gin-swagger v1.2.0
	github.com/swaggo/swag v1.6.3 // indirect
	golang.org/x/sys v0.0.0-20190626150813-e07cf5db2756 // indirect
)

replace gitlab.com/flotechnologies/flo-resource-event/docs v0.0.0 => ./docs
