package main

//decorator wrapper for service locator but with logging injected
type serviceLocatorWithLogs struct {
	sl  ServiceLocator
	log *Logger
}

func CreateServiceLocatorWithLogs(sl ServiceLocator, log *Logger) ServiceLocator {
	return &serviceLocatorWithLogs{sl, log.CloneAsChild("ServiceLocator")}
}

func (s *serviceLocatorWithLogs) RegisterName(name string, locator Locator) error {
	e := s.sl.RegisterName(name, locator)
	return s.log.IfErrorF(e, "RegisterName: %s -> %v", name, GetFunctionName(locator))
}

func (s *serviceLocatorWithLogs) LocateName(name string) interface{} {
	return s.sl.LocateName(name)
}

func (s *serviceLocatorWithLogs) CopyName(name string, svc interface{}) bool {
	return s.sl.CopyName(name, svc)
}

func (s *serviceLocatorWithLogs) SingletonName(name string) interface{} {
	return s.sl.SingletonName(name)
}

func (s *serviceLocatorWithLogs) Clone() ServiceLocator {
	return s.sl.Clone()
}

func (s *serviceLocatorWithLogs) Close() {
	s.log.Debug("Closing")
	defer s.log.Info("Closed")
	s.sl.Close()
}
