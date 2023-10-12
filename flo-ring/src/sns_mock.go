package main

type snsMockClient struct {
	Logger *Logger
}

func CreateSnsMockClient(log *Logger) SnsClient {
	l := log.CloneAsChild("MockSns")
	l.Notice("CreateSnsMockClient OK")
	return &snsMockClient{l}
}

func (s *snsMockClient) Publish(topic string, message string) error {
	s.Logger.Trace("Publish: %q | %s", topic, message)
	return nil
}

func (s *snsMockClient) Ping(topic string) error {
	s.Logger.Trace("Ping: %q", topic)
	return nil
}
