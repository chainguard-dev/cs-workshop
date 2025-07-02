# Cleanup

Examples of how you could implement cleanup and garbage collection policies to
control the amount of data stored in registry caches and mirrors.

## List Unused Files in Artifactory

List files in an Artifactory repository that have not been downloaded in X
number of days. This could serve as the input for an automated cleanup process.

Export your Artifactory URL and token.

```bash
export ARTIFACTORY_TOKEN="YOUR_AUTH_TOKEN_HERE"
export ARTIFACTORY_URL="https://foo.jfrog.io/artifactory"
```

Run the script with the name of the repository and the number of days as
arguments.

For instance, list files in `my-repository-cache` that haven't been downloaded
in the last 30 days.

```bash
./artifactory-list-unused-files.sh my-repository-cache 30
```

The output will look like this:

```
my-repository-cache/python/3.13.0/list.manifest.json
my-repository-cache/python/sha256__d23d952e9faa8d2884fd71d4473f65951cb5e0fb41f91d7d0db063bf77f7c56b/manifest.json
my-repository-cache/python/sha256__d23d952e9faa8d2884fd71d4473f65951cb5e0fb41f91d7d0db063bf77f7c56b/sha256__549e1c85c06388e2c7f9783321f2902bc8059e56cf82e364dbdcb73f162cb621
my-repository-cache/python/sha256__d23d952e9faa8d2884fd71d4473f65951cb5e0fb41f91d7d0db063bf77f7c56b/sha256__f5daf33d6ac5236e5a2b1d816d772663ee229eaee093e67092e40aecc022bb1f
```
