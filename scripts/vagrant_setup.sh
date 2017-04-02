#!/usr/bin/env bash
set -o pipefail

cd ~/entourage-ror

# Setup Ubuntu locale
cat <<EOF | sudo tee /etc/default/locale
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
EOF

# Install most dependencies from Ubuntu packages
sudo apt-get -yqq update
sudo apt-get -yqq install \
  build-essential \
  nodejs \
  postgresql postgresql-contrib postgis libpq-dev \
  redis-server

# Install Ruby via RVM
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
$rvm_recommended_ruby --quiet-curl --default
echo 'gem: --no-document' >> ~/.gemrc
gem install bundler

# Configure PostgreSQL authentication
sudo -u postgres createuser --superuser --createdb entourage || true
sudo sed -i 's|^\(local .*\) peer$|\1 trust|' /etc/postgresql/*/main/pg_hba.conf
sudo sed -i 's|^\(host .*\) md5$|\1 trust|' /etc/postgresql/*/main/pg_hba.conf
sudo service postgresql reload

# Setup app
bundle install --without production
bundle exec rake db:setup db:test:prepare
