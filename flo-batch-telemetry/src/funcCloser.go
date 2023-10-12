package main

// adaptor to tie any 2 void func together -> ICloser
type funcCloser struct {
	open   func()
	close  func()
	logger *Logger
}

func (f *funcCloser) Open() {
	if f == nil || f.open == nil {
		return
	}
	if f.logger != nil {
		f.logger.Debug("Open: (%p) %v", f.open, FunctionName(f.open))
	}
	f.open()
}

func (f *funcCloser) Close() {
	if f == nil || f.close == nil {
		return
	}
	if f.logger != nil {
		f.logger.Debug("Close: (%p) %v", f.close, FunctionName(f.close))
	}
	f.close()
}
