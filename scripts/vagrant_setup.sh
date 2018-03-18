#!/usr/bin/env bash

set -eo pipefail

RUBY_VERSION="2.3.1"
RUBY_INSTALL_VERSION="0.6.1"
CHRUBY_VERSION="0.3.9"


# install dependencies
cat <<EOF | sudo tee /etc/default/locale
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
EOF

sudo apt-get -yqq update
sudo apt-get -yqq install \
  build-essential \
  nodejs \
  postgresql postgresql-contrib postgis libpq-dev \
  redis-server libsqlite3-dev


###
# Install ruby
###

mkdir ruby
cd ruby

# add postmodern PGP key
wget https://raw.github.com/postmodern/postmodern.github.io/master/postmodern.asc
gpg --import postmodern.asc

# install ruby-install
wget -q "https://raw.github.com/postmodern/ruby-install/master/pkg/ruby-install-$RUBY_INSTALL_VERSION.tar.gz.asc"
wget -qO "ruby-install-$RUBY_INSTALL_VERSION.tar.gz" "https://github.com/postmodern/ruby-install/archive/v$RUBY_INSTALL_VERSION.tar.gz"
gpg --verify "ruby-install-$RUBY_INSTALL_VERSION.tar.gz.asc" "ruby-install-$RUBY_INSTALL_VERSION.tar.gz"
tar -xzvf "ruby-install-$RUBY_INSTALL_VERSION.tar.gz"
cd "ruby-install-$RUBY_INSTALL_VERSION/"
sudo make install

# install pinned ruby version
ruby-install ruby $RUBY_VERSION

# install chruby
wget -q "https://raw.github.com/postmodern/chruby/master/pkg/chruby-$CHRUBY_VERSION.tar.gz.asc"
wget -qO "chruby-$CHRUBY_VERSION.tar.gz" "https://github.com/postmodern/chruby/archive/v$CHRUBY_VERSION.tar.gz"
gpg --verify "chruby-$CHRUBY_VERSION.tar.gz.asc" "chruby-$CHRUBY_VERSION.tar.gz"
tar -xzvf "chruby-$CHRUBY_VERSION.tar.gz"
cd "chruby-$CHRUBY_VERSION/"
sudo make install
echo 'source /usr/local/share/chruby/chruby.sh' >> ~/.bashrc
echo 'chruby ruby' >> ~/.bashrc
source /usr/local/share/chruby/chruby.sh

# activate our ruby version
chruby ruby

# cleanup
cd ..
rm -rf ruby

###
# /Install ruby
###


# Configure PostgreSQL authentication
sudo -u postgres createuser --superuser --createdb entourage || true
sudo sed -i 's|^\(local .*\) peer$|\1 trust|' /etc/postgresql/*/main/pg_hba.conf
sudo sed -i 's|^\(host .*\) md5$|\1 trust|' /etc/postgresql/*/main/pg_hba.conf
sudo service postgresql reload

# Setup app
cd /home/vagrant/entourage-ror
echo 'gem: --no-document' >> ~/.gemrc
gem install bundler
bundle install --without production
bundle exec rake db:drop db:create db:migrate
bundle exec rake RAILS_ENV=test db:drop db:create db:migrate
