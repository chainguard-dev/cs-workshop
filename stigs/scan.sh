#!/bin/sh
oscap-docker container target xccdf eval \
  --profile 'xccdf_basic_profile_.check' \
  --report /out/report.html \
  --results /out/results.xml \
  /usr/share/xml/scap/ssg/content/ssg-chainguard-gpos-ds.xml