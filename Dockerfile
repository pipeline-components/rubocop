FROM ruby:2.7.1-alpine3.10 as build

# Ignore dependecies, they are for support only
# hadolint ignore=DL3018
RUN apk add --no-cache make build-base
RUN gem install bundler:2.0.2
RUN bundle config --global frozen 1

WORKDIR /app/
COPY app /app/
RUN bundle install --frozen --deployment --binstubs=/app/bin/ --no-cache --standalone
# Because --no-cache is broken https://github.com/bundler/bundler/issues/6680
RUN rm -vrf  vendor/bundle/ruby/*/cache

# app image
FROM pipelinecomponents/base-entrypoint:0.2.0 as entrypoint

FROM ruby:2.7.1-alpine3.10
COPY --from=entrypoint /entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
ENV DEFAULTCMD rubocop

WORKDIR /app/
COPY --from=build /app/ /app/
ENV PATH "${PATH}:/app/bin/"

WORKDIR /code/
# Build arguments
ARG BUILD_DATE
ARG BUILD_REF

# Labels
LABEL \
    maintainer="Robbert Müller <spam.me@grols.ch>" \
    org.label-schema.description="Rubocop in a container for gitlab-ci" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name="Rubocop" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://pipeline-components.gitlab.io/" \
    org.label-schema.usage="https://gitlab.com/pipeline-components/rubocop/blob/master/README.md" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-url="https://gitlab.com/pipeline-components/rubocop/" \
    org.label-schema.vendor="Pipeline Components"
