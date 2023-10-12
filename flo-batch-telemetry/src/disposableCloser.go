package main

type disposableCloser struct {
	killSig    *int32
	disposable IDisposable
	logger     *Logger
}

func (c *disposableCloser) Open() {
	if c == nil || c.disposable == nil || c.killSig == nil {
		return
	}
	if c.logger != nil {
		c.logger.Debug("Open: (%p) %v.Schedule()", c.disposable, TypeName(c.disposable))
	}
	c.disposable.Schedule(c.killSig)
}

func (c *disposableCloser) Close() {
	if c == nil || c.disposable == nil {
		return
	}
	if c.logger != nil {
		c.logger.Debug("Close: (%p) %v.Dispose()", c.disposable, TypeName(c.disposable))
	}
	c.disposable.Dispose()
}
