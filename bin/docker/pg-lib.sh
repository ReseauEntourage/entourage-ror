regex="postgres://(.+):(.+)@(.+):(.+)/(.+)"

function password {
  [[ $1 =~ $regex ]]
  password=${BASH_REMATCH[2]}
  echo $password
}

function options {
  [[ $1 =~ $regex ]]
  username=${BASH_REMATCH[1]}
  host=${BASH_REMATCH[3]}
  port=${BASH_REMATCH[4]}
  database=${BASH_REMATCH[5]}
  if [ "$2" = "-d" ]; then
    echo -U $username -h $host -p $port -d $database
  else
    echo -U $username -h $host -p $port $database
  fi
}

function dump {
  docker-compose exec -T \
    --env PGPASSWORD=$(password $1) \
    --env PGSSLMODE=prefer \
  postgresql pg_dump \
    --verbose \
    --format=custom \
    --compress=0 \
    $(options $1 -d) \
    "${@:2}"
}

function restore {
  docker-compose exec -T postgresql pg_restore \
    --verbose --no-acl --no-owner -U guest \
    --dbname=$1
}

function drop {
  docker-compose exec -T postgresql dropdb \
    --if-exists --echo -U guest \
    $1
}

function create {
  docker-compose exec  -T postgresql createdb \
    --echo -U guest \
    $1
}

function reset {
  drop $1
  create $1
}

function exclude {
  for table in "$@"; do
    echo -n "--exclude-table-data=$table "
  done
}
