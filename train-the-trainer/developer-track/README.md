# Developer Track


## Python Example 1

Build
```
docker build . -t python-example-1
```

Run 
```
docker run --rm python-example-1
```

This will fail when we try to run it because the `mariadb` packages that are installed in the dev stage are not available in the final stage.  This will be fixed in Python Example 2.

```
  File "/app/run.py", line 1, in <module>
    from MySQLdb import _mysql
  File "/app/venv/lib/python3.12/site-packages/MySQLdb/__init__.py", line 17, in <module>
    from . import _mysql
ImportError: libmariadb.so.3: cannot open shared object file: No such file or directory
```

## Python Example 2

Build
```
docker build . -t python-example-2
```

Run 
```
docker run --rm python-example-2
```

## Python Example 3 (Optional)

Same code example as Pythonn Example 2 except it uses a complied version of the main class

```
ENTRYPOINT ["python", "__pycache__/main.cpython-312.pyc"]
```

Build
```
docker build . -t python-example-3
```

Run 
```
docker run --rm python-example-3
```

## Java Example

Run through [this example](../../java/3step).

## Entrypoint Demo

Run through [this demo](./entrypoint).

## Health Checks Demo

Run through [this demo](./healthchecks).

## CLI Demo

### Demo script to showcase the following CLI commands

* Tag History API
* chainctl images diff
* crane - list image tags
* grype - scan image
* sfyt - create SBOM for image
* cosign - download SBOM")


```
./dtDemo.sh
```
