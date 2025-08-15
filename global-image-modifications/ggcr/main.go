package main

import (
	"context"
	"flag"
	"log"
	"os"

	"github.com/google/go-containerregistry/pkg/logs"
)

var (
	multiArch = flag.Bool("multi-arch", false, "Modify an entire multi-arch image.")
	platform  = flag.String("platform", "linux/amd64", "When -multi-arch is unset, resolve image indexes down to a specific platform.")
)

func init() {
	logs.Warn.SetOutput(os.Stderr)
	logs.Progress.SetOutput(os.Stderr)
}

func main() {
	flag.Parse()

	ctx := context.Background()

	// Parse args
	args := flag.Args()
	if len(args) != 2 {
		log.Fatalf("must provide two arguments: source image and destination image")
	}
	src := args[0]
	dst := args[1]

	// If --multi-arch is set then we expect the src to be an index
	if *multiArch {
		// See index.go
		if err := MutateImageIndex(ctx, src, dst); err != nil {
			log.Fatalf("customizing image index: %s", err)
		}
		return
	}

	// Otherwise, its an image OR we will resolve the index to the specific
	// platform
	//
	// See image.go
	if err := MutateImage(ctx, *platform, src, dst); err != nil {
		log.Fatalf("customizing image: %s", err)
	}

}
