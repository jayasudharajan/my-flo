package main

import (
	"fmt"
	"strings"
)

type SqlBuilder interface {
	Append(stmt string, arg ...interface{}) SqlBuilder
	Arg(v interface{}) int
	Close()
	String() string
	Len() int
	ArgsLen() int
	Args() []interface{}
}

func NewSqlBuilder() SqlBuilder {
	return &sqlBuilder{_loggerSbPool.Get(), make([]interface{}, 0)}
}

type sqlBuilder struct {
	sb   *strings.Builder
	args []interface{}
}

func (sq *sqlBuilder) Append(stmt string, arg ...interface{}) SqlBuilder {
	if stmt != "" {
		if len(arg) == 0 {
			sq.sb.WriteString(stmt)
		} else {
			sq.sb.WriteString(fmt.Sprintf(stmt, arg...))
		}
	}
	return sq
}

func (sq *sqlBuilder) Arg(v interface{}) int {
	sq.args = append(sq.args, v)
	return len(sq.args)
}

func (sq *sqlBuilder) Close() {
	if sq == nil {
		return
	}
	_loggerSbPool.Put(sq.sb)
	sq.args = nil
}

func (sq *sqlBuilder) Len() int {
	return sq.sb.Len()
}

func (sq *sqlBuilder) String() string {
	return sq.sb.String()
}

func (sq *sqlBuilder) ArgsLen() int {
	return len(sq.args)
}

func (sq *sqlBuilder) Args() []interface{} {
	return sq.args
}
