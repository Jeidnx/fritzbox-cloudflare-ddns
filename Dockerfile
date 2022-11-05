FROM bash

ADD sherver.sh /
ADD dispatcher.sh /
ADD update-template.sh /update.sh

RUN apk add --no-cache socat
RUN apk add --no-cache curl

ENTRYPOINT ["/sherver.sh"]