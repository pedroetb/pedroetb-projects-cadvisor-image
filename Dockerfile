ARG GOLANG_IMAGE_NAME=golang
ARG GOLANG_IMAGE_TAG=1.13.2-buster
ARG ALPINE_IMAGE_TAG=3.10.2
ARG BUILD_PATH=/go/src/github.com/google/cadvisor


FROM ${GOLANG_IMAGE_NAME}:${GOLANG_IMAGE_TAG} as build

ARG GIT_VERSION=1:2.20.1-2
RUN apt-get update && apt-get install -y --no-install-recommends \
		git=${GIT_VERSION} \
	&& rm -rf /var/lib/apt/lists/*

ARG BUILD_PATH

ARG CADVISOR_VERSION=master
RUN git clone \
	--branch ${CADVISOR_VERSION} \
	--depth 1 \
	https://github.com/google/cadvisor.git \
	${BUILD_PATH}

WORKDIR ${BUILD_PATH}

RUN make build


FROM alpine:${ALPINE_IMAGE_TAG}

LABEL maintainer="pedroetb@gmail.com"

ARG LIBC6_COMPAT_VERSION=1.1.22-r3
ARG DEVICE_MAPPER_VERSION=2.02.184-r0
ARG FINDUTILS_VERSION=4.6.0-r1
ARG THIN_PROVISIONING_TOOLS_VERSION=0.7.1-r2
RUN apk --no-cache add \
		libc6-compat=${LIBC6_COMPAT_VERSION} \
		device-mapper=${DEVICE_MAPPER_VERSION} \
		findutils=${FINDUTILS_VERSION} \
		thin-provisioning-tools=${THIN_PROVISIONING_TOOLS_VERSION} \
	&& echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

ARG BUILD_PATH
COPY --from=build ${BUILD_PATH}/cadvisor /usr/bin/cadvisor

EXPOSE 8080

HEALTHCHECK --interval=1m --timeout=30s --start-period=2m --retries=10 \
	CMD wget --quiet --tries=1 --spider http://localhost:8080/healthz || exit 1

ENTRYPOINT ["/usr/bin/cadvisor", "--logtostderr"]
