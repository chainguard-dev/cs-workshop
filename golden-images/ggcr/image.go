package main

import (
	"archive/tar"
	"bytes"
	"context"
	"fmt"
	"io"
	"strings"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/name"
	v1 "github.com/google/go-containerregistry/pkg/v1"
	"github.com/google/go-containerregistry/pkg/v1/mutate"
	"github.com/google/go-containerregistry/pkg/v1/remote"
	"github.com/google/go-containerregistry/pkg/v1/stream"
)

// MutateImage customizes a source image and pushes it to the destination. If
// the source image is an index, it is resolved down to the specific manifest
// for the provided platform.
func MutateImage(ctx context.Context, platform, src, dst string) error {
	p, err := v1.ParsePlatform(platform)
	if err != nil {
		return fmt.Errorf("parsing platform: %w", err)
	}

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
		remote.WithPlatform(*p),
		remote.WithAuthFromKeychain(authn.DefaultKeychain),
	}

	// Pull the image
	img, err := remote.Image(srcRef, opts...)
	if err != nil {
		return fmt.Errorf("pulling image: %w", err)
	}

	// Mutate it
	img, err = mutateImage(img)
	if err != nil {
		return fmt.Errorf("mutating image: %w", err)
	}

	// Push the mutated image to the destination
	if err := remote.Push(dstRef, img, opts...); err != nil {
		return fmt.Errorf("pushing image: %w", err)
	}

	return nil
}

func mutateImage(img v1.Image) (v1.Image, error) {
	// Get the image digest
	digest, err := img.Digest()
	if err != nil {
		return nil, fmt.Errorf("fetching digest for image: %w", err)
	}

	// Add annotations to the image
	annotations := map[string]string{
		"com.example.org.golden.image":         "true",
		"org.opencontainers.image.base.digest": digest.String(),
	}
	img = mutate.Annotations(img, annotations).(v1.Image)

	// Add the same values as labels
	cfg, err := img.ConfigFile()
	if err != nil {
		return nil, fmt.Errorf("fetching image config: %w", err)
	}
	cfg = cfg.DeepCopy()
	for k, v := range annotations {
		cfg.Config.Labels[k] = v
	}
	img, err = mutate.ConfigFile(img, cfg)
	if err != nil {
		return nil, fmt.Errorf("mutating image config: %w", err)
	}

	// Extract certificates from the image and append our caCert
	var caCertBundle []byte
	extracted := mutate.Extract(img)
	tr := tar.NewReader(extracted)
	for {
		hdr, err := tr.Next()
		if err == io.EOF {
			break
		}

		certPath := "/etc/ssl/certs/ca-certificates.crt"
		if hdr.Name != certPath && hdr.Name != strings.TrimPrefix(certPath, "/") {
			continue
		}

		bundle, err := io.ReadAll(tr)
		if err != nil {
			return nil, fmt.Errorf("extracting certificates: %w", err)
		}
		caCertBundle = append(append(bundle, caCert0...), '\n')
		break
	}
	extracted.Close()

	// Create a tar containing the modified cert bundle, the
	// certificate and some custom apk repository URLs
	fileMap := map[string][]byte{
		"etc/ssl/certs/ca-certificates.crt":                        caCertBundle,
		"usr/local/share/ca-certificates/custom-example-org-0.crt": caCert0,
		"etc/apk/repositories":                                     apkRepositories,
		"etc/apk/keys/chainguard-extras.rsa.pub":                   extrasSigningKey,
		"etc/apk/keys/wolfi-signing.rsa.pub":                       wolfiSigningKey,
	}
	buf := bytes.Buffer{}
	newTar := tar.NewWriter(&buf)
	for path, blob := range fileMap {
		header := &tar.Header{
			Name: path,
			Mode: 0644,
			Size: int64(len(blob)),
			Uid:  0,
			Gid:  0,
		}
		newTar.WriteHeader(header)
		if _, err := newTar.Write(blob); err != nil {
			return nil, fmt.Errorf("writing content to tar: %w", err)
		}
	}
	newTar.Close()

	// Append the tar to the image as a new layer
	img, err = mutate.Append(img, mutate.Addendum{Layer: stream.NewLayer(io.NopCloser(&buf))})
	if err != nil {
		return nil, fmt.Errorf("failed to append modified CA certificates to image: %s", err)
	}

	return img, nil
}

var caCert0 = []byte(`-----BEGIN CERTIFICATE-----
MIIFSzCCAzOgAwIBAgIUCFXjM0fyZECvzy6sZO6sT7LLc+wwDQYJKoZIhvcNAQEL
BQAwNTEQMA4GA1UEAwwHUm9vdCBDQTEUMBIGA1UECgwLRXhhbXBsZSBPcmcxCzAJ
BgNVBAYTAlVTMB4XDTI1MDcyMzExNTI1M1oXDTI2MDcyMzExNTI1M1owNTEQMA4G
A1UEAwwHUm9vdCBDQTEUMBIGA1UECgwLRXhhbXBsZSBPcmcxCzAJBgNVBAYTAlVT
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1CS0GJeFMNupBD5cZ2UV
SXx2TZNjopLQEV+Art9Ba4/Zwil8MJoawzwJ1FcWN/0a80K+bVOaMTNvmaAae1Kg
TWYMZ7+tqd06LQ1My/r31DqqgWfsz40EoFyOMTHhhI98j9JeID608Puug24QiqPZ
42EqZmQe0zwyLpA+r5clCyOwy/DrH55q3tZKDw7yQyBXbgeipTNYUHt4mTEbddN4
+Ls0Y2FhEWBXKgIeiE5kX69TvHw6Nx2rC9H37arvaeJkO9vCzSCW268fKHkrq0OF
sFo3jJw5D7AqKGabtcDqAJo28YmUziS1ynXhjd5kh4ut9F8PrdZU9O9T0ZabsPtE
5ETvv9V7j5RXrPlefjMqQCDb5OKG97A+O4oVGtWsrcIfPVyiNVYOj1Bpjc9S79IU
60KaP6EoElc81ByBAvUtxClNsqz2YG3qkE5fh6H+7qcBU0jNLJnpWH/dYJJ9meSv
uYWppY0GL+OxqA/2q/cU4646dTx+RDIOlSr71RnsCXyBLGZlrQ3ToHn6tEauUpKU
+9uex0OuZrDS23gg1uUk17FNXpRF14kgk7m44EHTVAxp1rQslUKinvZELDZO4AoA
lJe868racHfxV344G7WgPTcAPe6a3iFFvE1/T2uDdcHbU4LPoJq1mwA7RqjTvf/X
Bcz8eJzsOCH6OOkPflsoeEkCAwEAAaNTMFEwHQYDVR0OBBYEFJq8hhBdcAwPP8lj
B4HdUi8i5hZ/MB8GA1UdIwQYMBaAFJq8hhBdcAwPP8ljB4HdUi8i5hZ/MA8GA1Ud
EwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggIBAHlSQYCSBRwMbUmCuw4B33cJ
3QCGR++Q6ikxGqceNzgIZp7B3Qakt5KJzOEgdFHCj85Kd6V0UdKahDuY2gYwWiFv
BT5mu+ZClfY7F+z+A7ORIVz3LB3SGUFx3zFld76u/xU5fV0hNZ+PTm0jBjY8UhwW
iWFHIr6Z37cVaJS07d6LDbmW7vN139srf86h2G64qStEVVEXZkoMtY2Zq+vi5rmQ
4zESgBMP3Rz1Ay8WP8KaALyAQmlZQn1lSbnH1NlZGf5UdZXkDLqnmiD4AJdUkw4f
rB21QXSB+93jsaehRJ50QzopEEMxP3xOi7FsnOaZU19Sz6ThKl8Vy9OYjGppbWbI
KqNSFc3Rcg71+uhtcyu3IDLhHzqSQkjuwsSyA0fGW+fJzEP+HWf3ySremUBhN084
e2L9vZnJop3dqVEpK4Dt8dqRQMA9gyRCsPBiqs3gse/y2Kx+kXC01vb7zry5qijs
el2e2TdpYkeIbF1EF2Aqb723aDNpil9EV7XasVcAI2Ef6lyeHypDdrazp0sLa/Lk
u0SOSPNST6Q946E4kH+y4KY71j5mOUI9BIXzXxNV3jSEfNEu2YqG8mgX1K4QxufD
xaaR+cPtXi5rOIAx7tjuH4eauxT1ooapDfvzAakbiRLrfPGSDfyu7M7h3W73qM/w
2NeyARKOHxsn+oW4ANtc
-----END CERTIFICATE-----
`)

var apkRepositories = []byte(`https://packages.cgr.dev/extras
https://packages.wolfi.dev/os
`)

var wolfiSigningKey = []byte(`-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA5qQUHmzqX9oa/RS3OSgL
YTYB1mzvVmnWC0JXsAafdgRkavJ9xRhsXMKXWPKMghZw6UnkxuxQCZlB9UhaFqed
X7SWfQ8qRgECFmdGUjoeV7P3VUkg17RU0mUKsXZZF/2mU+jCGyk5eweKcLWrk6bn
lNNF1vBJ9EXbHdfvbQsA5GfLku5tJhqRJ4FVQAGCw+1JoSKu+o3q+6xP7z6kMfR9
cp54FSj48rTJUibbAv+cPtZ3AnbpjdyarV7SYMfxp14Q/KR0CJYDihG3CFoU+TaM
dr7LUrgXaYw7m7g8hA2PY1jF8aqDqVFjVu/csPKnKVQSqNHfm4C4gljwT6TDVhPe
6xKSGKfAUNvHx2RIqSsZJCh68Af+VnfuimbHMYzGhzV4/efihpJlYsDnOXJj/PeY
SbEIYG2yoI3AYvDFyFX2OAOtQ9d4TPs4zS4aDg4R3UseXLib46FX3ZTfIi1/W0IO
eC3AFU5mK+02jq+7swcGbgzem30dFA/B3n8NQExJjF2WlGNJxFw2WnJQqKIkIh0s
km5jaxJ28xYgik+bEgxy1LsilKTowdkbEPRKv36JGdap4dOEGR+LwZsM+ontF1AO
wY6tvwtZKJWhgj7ES3BdtiC1GA2htFnP90lA7KnKbSMOxwWtSCH8spitdPdzgI8G
SxrOb0SZs6ZFAxYYe3GlvS0CAwEAAQ==
-----END PUBLIC KEY-----`)

var extrasSigningKey = []byte(`-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxQe5KE+z6aPUl/FUzewy
MogEwmlWYyyUdkd7IIp3EFn3ml8cuC1YgMFhCJH/jjIzp0GShTNWbs9ZHrWUf66Y
fKiOfz970UgjocSx2KOiL1C3C9HlnqRPoUWgvhs7RpYRr4CPJJBtl5zb16BSoA0L
XIxNn/saFzb+DDaTTSg2HuWab2ZJlwI9Hoi6ViEeCLmTcBH+OOm4PfPcHVlBDIXs
Hs3Iwaypbf9txCtH0yynYUKz+IqKT5iSWe2rBEHIG7KE8uf0eNgITFRnqnQ751kI
qBkbyOMcGmAvdvrszY8lEmi8i+NMss0R7KOGLlOUV/U9eBAWq1gykm4ouCSQcoFm
TUJFAhPxZdLWyX2terIegJIpBNj+G7Q6bt9VD7PW+UfoyZbN4pgRk3+5v2QFJEAy
lIrebpc1Ca4xcWAM8GhD9XvHBWVLH9Q3GmQ8CtrVjHFeMrUVAMPmsTELZ0PRqost
MNBBUkyfk46iVi2HoC/sc8thSshDUmgbJs37lEo1/wB+l9l/RDxIn44SCvMWR6GV
jfDXdS+f4xR3D12hFbtInDWgQSek8tlHFCpQDpmtcQ6J38EkN4ZYUvLIoW4u74RG
SHH6dYe1sbDVOd0oxNPttXddRse/XOkHq/4G80AMRU0sytV0e7NauHIyNB4/DI+2
XwqkGfBhFCU7oKtwuixmBH0CAwEAAQ==
-----END PUBLIC KEY-----`)
