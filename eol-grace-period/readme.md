# EOL Grace Period Examples
- [EOL Grace Period Examples](#eol-grace-period-examples)
  - [Overview](#overview)
  - [Pre-requisites](#pre-requisites)
  - [Examples](#examples)
    - [Example - EOL Grace Period with the Chainguard Console](#example---eol-grace-period-with-the-chainguard-console)
    - [Example - Using the EOL Grace Period API](#example---using-the-eol-grace-period-api)
    - [Example - Using the EOL Grace Period API to find LTS Versions](#example---using-the-eol-grace-period-api-to-find-lts-versions)

## Overview
This document contains examples for End of Life Grace Period. These example cover the following scenarios:
1. Using the Console UI to identify which images are eligible for EOL Grace Period.
2. Using the end of life API to identity EOL Grace Period data about images.


This guide utilizes the cs-ttt-demo.dev registry, it is not necessary to use it if you have access to a private Chainguard Registry. **Note:** EOL Grace Period data is not available on the free-tier registry.


## Pre-requisites
1. Login access to a private Chainguard registry for the console example.
2. chainctl is installed and user has access to a private chainguard org for the API example. Chainctl install docs can be found [here](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/)
3. curl installed to use the API.
4. jq installed to parse API output.

## Demo

An automated demo that walks through the EOL Grace Period API.

It requires that you have access to the `cs-ttt-demo.dev` registry.

You must also have these tools installed:

- `chainctl`
- `curl`
- `jq`

Run it like:

```
$ ./demo.sh
```

## Examples
This section walks through some examples of using EOL Grace Period.

### Example - EOL Grace Period with the Chainguard Console
This is meant to be a straightforward example of finding EOL images in the console.

1. Login to the [Chainguard console](https://console.chainguard.dev)
2. Select the org (if you have multiple) to use, this demo uses the cs-ttt-demo.dev Chainguard org.
3. Select Organization Images tab
4. Select the `python` image
5. Observe the image tags displayed. Image tags that are eligible for EOL Grace Period will will have text that reads `Grace period ends <date>` This indicates that the EOL date for the tag is within 6 months, the image tag will be included in the EOL Grace Period, and that the Grace Period will end on the date listed. 
6. Select the `custom-python-ui-demo` image.  Note that custom assembly images are also included in the EOL Grace Period Offering as you can see EOL data on this page.
7. Select the `tomcat` image. Note that there is no EOL data present for any image tag indicating that this image is not eligible for EOL Grace Period.

### Example - Using the EOL Grace Period API

This example utilizes to EOL API to obtain EOL data about images. The specification can be found [here](https://edu.chainguard.dev/chainguard/administration/api/#/operations/Registry_ListEolTags)

1. Using chainctl list the organizations repos:

**Note:** Update ORGANIZATION if you do not have access to the `cs-ttt-demo.dev` Chainguard registry.

```
ORGANIZATION="cs-ttt-demo.dev"
chainctl images repos list --parent $ORGANIZATION -o wide
```

This command lists all of the images in the organization:

```
                             ID                             |        REGISTRY         |                REPO                 |    BUNDLES     |    TIER      
------------------------------------------------------------+-------------------------+-------------------------------------+----------------+--------------
  c3e56b2c1e4eb0f6fe58807915db594950817ca3/4f6f5664843dde97 | cgr.dev/cs-ttt-demo.dev | jdk                                 | base, featured | BASE         
  c3e56b2c1e4eb0f6fe58807915db594950817ca3/9bb950f24521bb42 | cgr.dev/cs-ttt-demo.dev | jre                                 | base, featured | BASE         
  c3e56b2c1e4eb0f6fe58807915db594950817ca3/bdcfd909866af652 | cgr.dev/cs-ttt-demo.dev | kube-webhook-certgen                |                | APPLICATION  
  c3e56b2c1e4eb0f6fe58807915db594950817ca3/c588b7233b418204 | cgr.dev/cs-ttt-demo.dev | mariadb                             | application    | APPLICATION  
  c3e56b2c1e4eb0f6fe58807915db594950817ca3/38420c6478bcdb50 | cgr.dev/cs-ttt-demo.dev | maven                               | application    | APPLICATION  
  c3e56b2c1e4eb0f6fe58807915db594950817ca3/464780cadf15eeb7 | cgr.dev/cs-ttt-demo.dev | node                                | base, featured | BASE         
  c3e56b2c1e4eb0f6fe58807915db594950817ca3/4952f87ed307bb75 | cgr.dev/cs-ttt-demo.dev | node-custom                         | base, featured | BASE         
  c3e56b2c1e4eb0f6fe58807915db594950817ca3/4abdd72ba6cf22c6 | cgr.dev/cs-ttt-demo.dev | python                              | base, featured | BASE         
  c3e56b2c1e4eb0f6fe58807915db594950817ca3/78722b75aa9ff603 | cgr.dev/cs-ttt-demo.dev | tomcat                              | base           | APPLICATION  
```

Select an ID from the output above to get end of life data for that image, in this example we will be using the `node` image:

```
IMAGE_ID="c3e56b2c1e4eb0f6fe58807915db594950817ca3/464780cadf15eeb7"
curl -H "Authorization: Bearer $(chainctl auth token)" https://console-api.enforce.dev/registry/v1/eoltags\?uidp.children_of\=$IMAGE_ID  | jq .
```

You should see all of the EOL information for the selected image, lets take a closer look at the `node:24` image:

```
{
  "items": [
    ...
    {
      "id": "c3e56b2c1e4eb0f6fe58807915db594950817ca3/464780cadf15eeb7/510d0dbb69175563",
      "name": "24",
      "mainPackageName": "nodejs",
      "tagStatus": "TAG_ACTIVE",
      "mainPackageVersion": {
        "eolDate": "2028-04-30",
        "exists": true,
        "fips": false,
        "lts": "2025-10-28",
        "releaseDate": "2025-05-06",
        "version": "24",
        "eolBroken": false
      },
      "graceStatus": "GRACE_ELIGIBLE",
      "gracePeriodExpiryDate": null
    },
    ...
  ]
}
```

In the above output the name correlates with the image tag. In the example above this would be referring to the `node:24` image. Some other important items to look at include: 
* name - This is the image tag
* tagStatus - Indicates if the image tag is currently receiving updates (TAG_ACTIVE), currently in grace period (TAG_IN_GRACE) or the tag is no longer in grace period or receiving updates (TAG_INACTIVE).
* mainPackageVersion - This section block contains the EOL information, release date, eol date, if its an Long Term Supported (LTS) version. If the eolBroken key is set to `true` this indicates the EOL grace period was terminated early due to failures.
* graceStatus - indicates if the tag is eligible for EOL Grace Period (GRACE_ELIGIBLE), ineligible (GRACE_NOT_ELIGIBLE), or currently in a grace period (GRACE_ACTIVE)
* gracePeriodExpiryData - If the tag is in an active grace period (graceStatus is GRACE_ACTIVE) this indicates when the grace period will expire.

Below is an example of a tag that is currently in a grace period:
```
    {
      "id": "c3e56b2c1e4eb0f6fe58807915db594950817ca3/464780cadf15eeb7/92d72f3dd45fce1a",
      "name": "18",
      "mainPackageName": "nodejs",
      "tagStatus": "TAG_IN_GRACE",
      "mainPackageVersion": {
        "eolDate": "2025-04-30",
        "exists": true,
        "fips": false,
        "lts": "2022-10-25",
        "releaseDate": "2022-04-19",
        "version": "18",
        "eolBroken": false
      },
      "graceStatus": "GRACE_ACTIVE",
      "gracePeriodExpiryDate": "2025-10-30T00:00:00Z"
    }
```

Lets look at the tomcat image:
```
IMAGE_ID="c3e56b2c1e4eb0f6fe58807915db594950817ca3/78722b75aa9ff603"
curl -s -H "Authorization: Bearer $(chainctl auth token)" https://console-api.enforce.dev/registry/v1/eoltags\?uidp.children_of\=$IMAGE_ID  | jq .
```

Observe one of the tag outputs:

```
    {
      "id": "c3e56b2c1e4eb0f6fe58807915db594950817ca3/78722b75aa9ff603/9c1fc7548b2dd21a",
      "name": "latest",
      "mainPackageName": "tomcat-11.0-openjdk",
      "tagStatus": "TAG_ACTIVE",
      "mainPackageVersion": {
        "eolDate": "",
        "exists": false,
        "fips": false,
        "lts": "",
        "releaseDate": "",
        "version": "21",
        "eolBroken": false
      },
      "graceStatus": "GRACE_NOT_ELIGIBLE",
      "gracePeriodExpiryDate": null
    },
```

You may notice that the graceStatus for all the Tomcat image tags is set to `GRACE_NOT_ELIGIBLE` indicating that the tomcat image is not eligible for EOL Grace Period.


### Example - Using the EOL Grace Period API to find LTS Versions

Another valuable use case for the EOL Grace Period API is to help enforce internal usage of Long-Term Support (LTS) image versions. Many organizations prefer to restrict access to only LTS-tagged images for stability and compliance reasons. The EOL Grace Period API can assist in this effort by programmatically identifying LTS versions of a given image.

For example, using the node image, the following API call can be used to retrieve only the tags associated with LTS versions that are currently active:

```
IMAGE_ID="c3e56b2c1e4eb0f6fe58807915db594950817ca3/464780cadf15eeb7"
curl -H "Authorization: Bearer $(chainctl auth token)" https://console-api.enforce.dev/registry/v1/eoltags\?uidp.children_of\=$IMAGE_ID | jq '.items[] | select((.mainPackageVersion != null) and (.mainPackageVersion.lts != "") and (.tagStatus == "TAG_ACTIVE"))'
```
