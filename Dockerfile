FROM docker.io/library/ruby:3.4.5-slim as build

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    gcc \
    libgit2-dev \
    cmake \
    pkg-config \
    libyaml-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Ensure rugged is built with SSH support
ENV CMAKE_FLAGS='-DUSE_SSH=ON'

COPY .bundle Gemfile Gemfile.lock ./
RUN bundle install --deployment --jobs=4 --without development test \
    && bundle clean

COPY . .

FROM docker.io/library/ruby:3.4.5-slim as run

WORKDIR /app

COPY --from=build /app /app

RUN bundle config --local path vendor/bundle
RUN bundle config --local without development:test

ARG UID=30000
ARG GID=$UID
RUN groupadd -g "${GID}" -r oxidized && useradd -u "${UID}" -r -m -d /home/oxidized -g oxidized oxidized
USER oxidized

ENTRYPOINT ["bundle", "exec", "oxidized"]
CMD ["--version"]
