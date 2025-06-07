FROM cgr.dev/chainguard/python:latest-dev as utils

USER root
RUN apk add --no-cache cmd:getent cmd:useradd cmd:groupadd

FROM cgr.dev/chainguard/python:latest-dev

# Libraries required by useradd/groupadd
COPY --from=utils /usr/lib/libbsd.so.* /usr/lib/
COPY --from=utils /usr/lib/libmd.so.* /usr/lib/
COPY --from=utils /usr/bin/useradd /usr/bin/useradd
COPY --from=utils /usr/bin/groupadd /usr/bin/groupadd

COPY --from=utils /usr/bin/getent /usr/bin/getent
