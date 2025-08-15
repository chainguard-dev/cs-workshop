package main

import (
	"context"
	"fmt"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/name"
	v1 "github.com/google/go-containerregistry/pkg/v1"
	"github.com/google/go-containerregistry/pkg/v1/empty"
	"github.com/google/go-containerregistry/pkg/v1/mutate"
	"github.com/google/go-containerregistry/pkg/v1/remote"
)

// MutateImageIndex customizes each image in an index, creates a new index
// and pushes it to the destination.
func MutateImageIndex(ctx context.Context, src, dst string) error {
	// Parse the source image URL
	srcRef, err := name.ParseReference(src)
	if err != nil {
		return fmt.Errorf("parsing src image: %w", err)
	}

	// Parse the destination image URL
	dstRef, err := name.NewTag(dst)
	if err != nil {
		return fmt.Errorf("parsing dst tag: %w", err)
	}

	// Authentication is handled transparently by the authn.DefaultKeychain which
	// will pick up the users and credential helpers configured in
	// `.docker/config.json`.
	opts := []remote.Option{
		remote.WithContext(ctx),
		remote.WithAuthFromKeychain(authn.DefaultKeychain),
	}

	// Pull the image index
	idx, err := remote.Index(srcRef, opts...)
	if err != nil {
		return fmt.Errorf("pulling image: %w", err)
	}

	// Get the index digest
	digest, err := idx.Digest()
	if err != nil {
		return fmt.Errorf("fetching digest for image: %w", err)
	}

	// Add annotations to the index
	annotations := map[string]string{
		"com.example.org.golden.image":         "true",
		"org.opencontainers.image.base.digest": digest.String(),
	}
	idx = mutate.Annotations(idx, annotations).(v1.ImageIndex)

	// Iterate over each manifest in the index and mutate each image
	im, err := idx.IndexManifest()
	if err != nil {
		return fmt.Errorf("getting index manifest: %w", err)
	}
	adds := []mutate.IndexAddendum{}
	for _, desc := range im.Manifests {
		img, err := idx.Image(desc.Digest)
		if err != nil {
			return fmt.Errorf("getting image: %w", err)
		}
		// see image.go
		mutated, err := mutateImage(img)
		if err != nil {
			return fmt.Errorf("mutating image: %w", err)
		}

		adds = append(adds, mutate.IndexAddendum{
			Add: mutated,
			Descriptor: v1.Descriptor{
				URLs:        desc.URLs,
				MediaType:   desc.MediaType,
				Annotations: desc.Annotations,
				Platform:    desc.Platform,
			},
		})
	}

	// Create a brand new index
	nidx := mutate.IndexMediaType(empty.Index, im.MediaType)
	nidx = mutate.Annotations(nidx, im.Annotations).(v1.ImageIndex)
	nidx = mutate.AppendManifests(nidx, adds...)

	// Push the modified image to the destination
	if err := remote.Push(dstRef, nidx, opts...); err != nil {
		return fmt.Errorf("pushing image: %w", err)
	}

	return nil
}
