FROM public.ecr.aws/amazonlinux/amazonlinux:latest as builder

RUN yum install -y \
    gcc \
    libc-dev \
    git \
    golang \
    wget \
    ca-certificates
RUN go env -w GOPROXY=direct GOPATH=/go

WORKDIR /go/src/app
RUN wget https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/plugin/out_coralogix.go && \
    go get . && \
    go build -buildmode=c-shared -o out_coralogix.so .

FROM amazon/aws-for-fluent-bit:2.10.0
COPY entrypoint_with_coralogix.sh /entrypoint_with_coralogix.sh
RUN chmod +x /entrypoint_with_coralogix.sh
COPY --from=builder /go/src/app/out_coralogix.so /fluent-bit/plugins/out_coralogix.so

CMD /entrypoint_with_coralogix.sh
