FROM heroku/heroku:16

WORKDIR /home/docker-user/app

RUN useradd docker-user \
 && chown -R docker-user:docker-user /home/docker-user

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash

RUN apt-get update \
 && apt-get -y --no-install-recommends install \
      build-essential \
      libgmp-dev \
      libpq-dev \
      libsqlite3-dev \
      libssl-dev \
      locales \
      nodejs \
      zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN npm install -g aglio --unsafe

RUN mkdir -p /opt/rubies/2.3.1 \
 && curl -s http://s3.amazonaws.com/heroku-buildpack-ruby/heroku-16/ruby-2.3.1.tgz \
  | tar xzC /opt/rubies/2.3.1

RUN mkdir /tmp/chruby \
 && curl -sL https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz \
  | tar xzC /tmp/chruby --strip-components=1 \
 && su docker-user /bin/bash -c " \
      source /tmp/chruby/share/chruby/chruby.sh \
   && chruby 2.3.1 \
   && export PATH=bin:\$PATH \
   && env" \
  | grep -E '^(GEM|RUBY|PATH)' | sort | sed 's|^|export |' > /etc/profile.d/ruby.sh \
 && rm -r /tmp/chruby

RUN su docker-user /bin/bash -c "\
      source /etc/profile.d/ruby.sh \
   && echo gem: --no-document > ~/.gemrc \
   && mkdir ~/.gem \
   && gem install bundler foreman"

RUN \
  repo=https://github.com/rbspy/rbspy; \
  tag=$(curl -sLI -o /dev/null -w %{url_effective} $repo/releases/latest | cut -d/ -f8); \
  tar=$repo/releases/download/$tag/rbspy-$tag-x86_64-unknown-linux-musl.tar.gz; \
  curl -sL $tar | tar xzC /usr/local/bin

RUN echo '#!/bin/bash -l'      >> /entrypoint \
 && echo 'exec "$@"'           >> /entrypoint \
 && chmod +x                      /entrypoint \
 && chown docker-user:docker-user /entrypoint

ENTRYPOINT ["/entrypoint"]

CMD ["bash"]
