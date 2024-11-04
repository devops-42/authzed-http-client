# ------------------------------------------------------------------------------------------------------

FROM netdata/wget:latest AS download

ARG authzed_version="v1.1.0"
ENV SECS=10
RUN wget -O /tmp/openapi-spec.json "https://raw.githubusercontent.com/authzed/authzed-go/refs/tags/${authzed_version}/proto/apidocs.swagger.json"

# ------------------------------------------------------------------------------------------------------

FROM openapitools/openapi-generator-cli:v7.9.0 AS java-restclient

COPY --from=download /tmp/openapi-spec.json /tmp/openapi-spec.json

RUN mkdir -p /tmp/build/java-restclient
WORKDIR /tmp/build/java-restclient

ARG java_version="21"
ARG authzed_version="v1.1.0"
ARG artifact_version="0.0.0"
ARG library="restclient"

ADD cfg/java.yml /etc/java.yml

RUN bash /usr/local/bin/docker-entrypoint.sh \
        generate \
        -g java \
        -i /tmp/openapi-spec.json \
        -c /etc/java.yml \
        -o "/tmp/build/java-${library}" \
        -p "library=restclient" \
        -p artifactId=authzed-http-client-restclient \
        -p "artifactVersion=${artifact_version}-${java_version}-${authzed_version}-SNAPSHOT"

# ------------------------------------------------------------------------------------------------------

FROM openapitools/openapi-generator-cli:v7.9.0 AS typescript-fetch

COPY --from=download /tmp/openapi-spec.json /tmp/openapi-spec.json

RUN mkdir -p /tmp/build/typescript-fetch
WORKDIR /tmp/build/typescript-fetch

ARG node_version="21"
ARG authzed_version="v1.1.0"
ARG artifact_version="0.0.0"

ADD cfg/typescript-fetch.yml /etc/typescript-fetch.yml

RUN bash /usr/local/bin/docker-entrypoint.sh \
        generate \
        -g typescript-fetch \
        -i /tmp/openapi-spec.json \
        -c /etc/typescript-fetch.yml \
        -o "/tmp/build/typescript-fetch" \
        --git-host "github.com" \
        --git-repo-id "authzed-http-client" \
        --git-user-id "ewerk" \
        -p npmName="@ewerk/authzed-http-client-restclient" \
        -p "npmVersion=${artifact_version}-${node_version}-${authzed_version}" \
        -p "snapshot=true"

# ------------------------------------------------------------------------------------------------------

FROM scratch AS artifacts

LABEL org.opencontainers.image.authors="info@ewerk.com"

COPY --from=java-restclient /tmp/build/java-restclient /java-restclient
COPY --from=typescript-fetch /tmp/build/typescript-fetch /typescript-fetch
