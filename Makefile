print-%:
	@echo '$($*)'

initialize:
	@echo "> initialize..."
	docker-compose down --volumes && docker-compose --verbose up -d
	sleep 5 # wait for postgres to start
	RAILS_ENV=development docker-compose run web rake db:drop db:create db:migrate
	RAILS_ENV=test        docker-compose run web rake db:drop db:create db:migrate

log:
	@echo "> log..."

build:
	USER_ID=$$UID docker-compose build

test:
	docker-compose run web bin/rspec

.PHONY: all print initialize test
