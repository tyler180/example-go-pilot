package main

import (
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	if os.Getenv("AWS_LAMBDA_RUNTIME_API") != "" {
		lambda.Start(handleGreeting)
		return
	}
	name := flag.String("name", "Go pilot", "name to greet")
	flag.Parse()
	fmt.Println(greeting(*name))
	fmt.Println("testing a change")
	fmt.Println("testing another change")
}

type greetingRequest struct {
	Name string `json:"name"`
}

type greetingResponse struct {
	Greeting string `json:"greeting"`
}

func handleGreeting(request greetingRequest) (greetingResponse, error) {
	return greetingResponse{Greeting: greeting(request.Name)}, nil
}

func greeting(name string) string {
	name = strings.TrimSpace(name)
	if name == "" {
		name = "world"
	}
	return fmt.Sprintf("Hello, %s!", name)
}
