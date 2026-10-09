////////////////////////////////////////////////////////////
// Sample Go application for multi-stage Docker demo
// This is a simple HTTP server that responds with "Hello!"
////////////////////////////////////////////////////////////

package main

import (
	"fmt"
	"log"
	"net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello from a Go container! 🚀 Image size: ~12MB thanks to multi-stage builds!")
}

func main() {
	http.HandleFunc("/", handler)
	log.Println("Server starting on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
