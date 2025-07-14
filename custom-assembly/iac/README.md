# Custom Assembly: Infrastructure as Code Example

This is an example of how you could manage Custom Assembly images
declaratively with an IaC/GitOps approach.

## How it Works

Each YAML file under [`images/`](images/) represents a Chainguard image
repository with the naming convention `images/{name}.yaml`.

This example does not recommend a specific CI/CD solution. Instead it provides
generic scripts that could be ran in response to GitHub repository events in
any given workflow engine.

### Pre Submit

The `presubmit.sh` script is designed to run as part of the checks on a Pull
Request. It validates that the yaml files are valid.

It performs the following checks.

1. Ensures that the image described by the file exists and is enabled for
   Custom Assembly.
2. Validates that each package described by the configuration exists in the
   private APK repository that Custom Assembly uses.

### Post Submit

The `postsubmit.sh` script is designed to run when changes are merged to the
`main` branch. It applies each of the yaml files with `chainctl image repo build
apply`.

## Usage

### IAM

Before running the scripts, you must login to Chainguard with `chainctl auth
login`.

You must be an `owner` in the organization. Or, you can construct a [custom
role](https://edu.chainguard.dev/chainguard/administration/iam-organizations/roles-role-bindings/roles-role-bindings/)
with the `repo.update` permission.

For your automation, create an [Assumable
Identity](https://edu.chainguard.dev/chainguard/administration/assumable-ids/assumable-ids/)
to run the scripts with. The kind of identity will depend on the platform your
pipelines are hosted in.

### Checking Available Packages

Not all packages are available via Custom Assembly. Before adding a package to
an image, you can check if it's available by querying the index of the private
APK repository used by Custom Assembly.

You must have the `apk (list)` capability in your organization to do this. This
is provided by the `apk.pull` role or other more privileged roles like `viewer`
or `owner`.

```shell
export ORGANIZATION=your.org

curl \
    -sSf \
    -u "_token:$(chainctl auth token --audience apk.cgr.dev)" \
    "https://apk.cgr.dev/${ORGANIZATION}/x86_64/APKINDEX.tar.gz" \
    | tar -xOz APKINDEX \
    | grep '^P:curl$'
```
