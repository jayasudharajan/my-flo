package main

import "fmt"

type ErrorResponse struct {
	StatusCode int    `json:"status"`
	Message    string `json:"message"`
}

func (er *ErrorResponse) Error() string { //to satisfy go error interface
	if er != nil {
		return fmt.Sprintf("%v - %v", er.StatusCode, er.Message)
	}
	return ""
}
