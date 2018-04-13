FROM heroku/heroku:16

WORKDIR /app

RUN useradd --home /app heroku-user \
    && chown -R heroku-user:heroku-user /app

RUN apt-get update \
    && apt-get -y --no-install-recommends install \
         build-essential \
         libpq-dev \
         libsqlite3-dev \
         libssl-dev \
         nodejs \
         ruby-dev \
         zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/rubies/2.3.1 \
    && curl -s http://s3.amazonaws.com/heroku-buildpack-ruby/heroku-16/ruby-2.3.1.tgz \
    | tar xzC /opt/rubies/2.3.1

RUN mkdir /tmp/chruby \
    && curl -sL https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz \
    | tar xzC /tmp/chruby --strip-components=1 \
    && cd /tmp/chruby \
    && make install \
    && rm -r /tmp/chruby \
    && echo source /usr/local/share/chruby/chruby.sh >> /etc/profile.d/chruby.sh \
    && echo chruby 2.3.1 >> /etc/profile.d/chruby.sh

RUN echo gem: --no-document > ~/.gemrc \
    && /bin/bash -c '\
      source /etc/profile.d/chruby.sh \
      && gem install bundler'

RUN echo unset HISTFILE >> /etc/profile.d/no_history.sh

RUN mkdir .gem && chown heroku-user:heroku-user .gem

ENV BASH_ENV /etc/profile
ENTRYPOINT ["/bin/bash", "-c"]

CMD ["bash -l"]
