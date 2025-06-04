# Python Example

An example of migrating a Python application to use Chainguard Containers.

## Interactive Demo

Requires that `docker`, `git` and `grype` are available locally.

Run `./demo.sh` and step through the commands.

## Examples

### Single Stage (Broken)

Diff the changes.

```
git diff --no-index Dockerfile singlestage-broken.Dockerfile
```

Build the image.

```
docker build -t python-example:singlestage-broken -f singlestage-broken.Dockerfile .
```

This will fail because `mariadb` isn't installed. This is included in
`python:latest` but is not part of the Chainguard image by default. This will be
fixed in the next example.

```
 > [3/4] RUN pip install --no-cache-dir -r requirements.txt:
0.402 Defaulting to user installation because normal site-packages is not writeable
0.524 Collecting mysqlclient (from -r requirements.txt (line 1))
0.625   Downloading mysqlclient-2.2.7.tar.gz (91 kB)
0.670   Installing build dependencies: started
1.597   Installing build dependencies: finished with status 'done'
1.598   Getting requirements to build wheel: started
1.768   Getting requirements to build wheel: finished with status 'error'
1.771   error: subprocess-exited-with-error
1.771
1.771   × Getting requirements to build wheel did not run successfully.
1.771   │ exit code: 1
1.771   ╰─> [31 lines of output]
1.771       Trying pkg-config --exists mysqlclient
1.771       Command 'pkg-config --exists mysqlclient' returned non-zero exit status 1.
1.771       Trying pkg-config --exists mariadb
1.771       Command 'pkg-config --exists mariadb' returned non-zero exit status 1.
1.771       Trying pkg-config --exists libmariadb
1.771       Command 'pkg-config --exists libmariadb' returned non-zero exit status 1.
1.771       Trying pkg-config --exists perconaserverclient
1.771       Command 'pkg-config --exists perconaserverclient' returned non-zero exit status 1.
1.771       Traceback (most recent call last):
1.771         File "/usr/lib/python3.13/site-packages/pip/_vendor/pyproject_hooks/_in_process/_in_process.py", line 389, in <module>
1.771           main()
1.771           ~~~~^^
```

### Single Stage (Fixed)

Diff with the broken approach.

```
git diff --no-index singlestage-broken.Dockerfile singlestage.Dockerfile
```

Build the image.

```
docker build -t python-example:singlestage -f singlestage.Dockerfile .
```

Run it.

```
docker run --rm python-example:singlestage
```

### Multi Stage (Broken)

Diff with the single stage approach.

```
git diff --no-index singlestage.Dockerfile multistage-broken.Dockerfile
```

Build the image.

```
docker build -t python-example:multistage-broken -f multistage-broken.Dockerfile .
```

Run it.

```
docker run --rm python-example:multistage-broken
```

This will fail when we try to run it because the `mariadb` packages that are
installed in the dev stage are not available in the final stage. This will be
fixed in the next example.

```
  File "/app/run.py", line 1, in <module>
    from MySQLdb import _mysql
  File "/app/venv/lib/python3.12/site-packages/MySQLdb/__init__.py", line 17, in <module>
    from . import _mysql
ImportError: libmariadb.so.3: cannot open shared object file: No such file or directory
```

### Multi Stage (Fixed)

Diff with the broken example.

```
git diff --no-index multistage-broken.Dockerfile multistage.Dockerfile
```

Build the image.

```
docker build -t python-example:multistage -f multistage.Dockerfile .
```

Run it.

```
docker run --rm python-example:multistage
```

### Base Chroot

Diff against the other multi stage approach.

```
git diff --no-index multistage.Dockerfile base-chroot.Dockerfile
```

Build the image.

```
docker build -t python-example:base-chroot -f base-chroot.Dockerfile .
```

Run it.

```
docker run --rm python-example:base-chroot
```
