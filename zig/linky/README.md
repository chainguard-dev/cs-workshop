# Zig Example

## Using the Chainguard Image
1. cd into the linky directory
```
cd linky
```

2. Build the application
```
docker build -t zig-linky .
```

3. Run the image
```
docker run -p 8080:8080 --rm zig-linky
```

4. Test application
Open http://localhost:8080/foo
Open http://localhost:8080/test

5. Scan the image:
```
grype zig-linky
```

## Takeaways
1. 0 vulnerabilities from the grype scan (it's a static image)
2. Mutltistage build
3. Number of package, files, etc.
