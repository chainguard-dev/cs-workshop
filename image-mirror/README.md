# Image Mirror Examples

These are examples of custom scripts for mirroring images from `cgr.dev` to
another registry.

## Scripts

### Basic

See: [`./basic`](./basic) 

This simple example iterates through the latest images in a `cgr.dev` repository
and mirrors them to a destination registry.

### Advanced

See: [`./advanced`](./advanced)

This a more complex example that filters out image updates unless they resolve
vulnerabilities.
