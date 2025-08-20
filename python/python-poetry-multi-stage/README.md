# python-poetry-multistage

An example of a Chainguard multi-stage image build for a 'Hello World' Python image leveraging poetry

## Usage

```
git clone https://github.com/chainguard-dev/python-poetry-multistage.git
```

```
docker build -t python-poetry-test:latest .
```

### Run the image locally 
```
docker run --name poetry.container -p 8000:8000 python-poetry-test:latest

INFO:     Started server process [1]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit
```

You should see the hello world page now at http://0.0.0.0:8000

