UP_P_CHOICE := N
up: ## コンテナ起動
	@read -p "Run as background? (y/N) [$(UP_P_CHOICE)]:" choice; \
		choice=$${choice:-$(UP_P_CHOICE)}; \
		if [ $$choice = y ]; then \
			docker-compose up -d; \
		else \
			docker-compose up; \
		fi

exec: ## コンテナに入る
	@docker exec -it clicknote-app-1 bash

down: ## コンテナ削除
	@docker-compose down
	@docker system prune -f > /dev/null

install: ## プロジェクトを初期化する
	@ls -a | grep -xv -E '.git|.git/|.vscode|.vscode/|docker-compose.yml|docker-compose.yaml|Dockerfile|Makefile|.|./|..|../' | xargs rm -rf
	@rm .vscode/settings.json || true

	@docker-compose run --rm app npm create vue@latest app \
		&& echo Move app project to root directory \
		&& mv app/.vscode/settings.json ./.vscode/ \
		&& rm -rf app/.vscode \
		&& mv app/* . \
		&& mv app/.* . \
		&& rm -rf app

	@echo && echo npm install
	@docker-compose run --rm app npm install
	@echo && echo npm install other tools
	@docker-compose run --rm app npm i postman-to-openapi-cli
	@docker-compose run --rm app npm i @openapitools/openapi-generator-cli

npm:
	@docker-compose run --rm app npm install

npmg:
	@docker-compose run --rm app npm i postman-to-openapi-cli
	@docker-compose run --rm app npm i @openapitools/openapi-generator-cli

GEN.API_P_CHOICE := N
gen.api:
	@rm -rf .api || true
	@mkdir .api || true
	@read -p "Download ClickUp API Postman collection? (y/N) [$(GEN.API_P_CHOICE)]:" choice; \
		choice=$${choice:-$(GEN.API_P_CHOICE)}; \
		if [ $$choice = y ]; then \
			curl https://www.postman.com/collections/38183835-c23d3a28-babc-4702-88fa-9e447936aa98?access_key=PMAK-679cf2540bdb150001052871-78a7f9bd59e2f4c808908e63d0e5b9973f -o .api/clickup; \
			echo "sed -i 's/{{baseUrl}}/https:\/\/api.clickup.com\/api/g' .api/clickup" > .api/sed.sh; \
			sh .api/sed.sh; \
			docker-compose run --rm app npx postman-to-openapi -s .api/clickup -o openapi-clickup.yml; \
		fi
	docker run --rm -v "${PWD}:/local" openapitools/openapi-generator-cli generate \
    	-i local/openapi-clickup.yml \
		-g typescript-node \
		--skip-validate-spec \
    	-o local/.api/node
	docker run --rm -v "${PWD}:/local" openapitools/openapi-generator-cli generate \
    	-i local/openapi-clickup.yml \
		-g typescript-axios \
		--skip-validate-spec \
    	-o local/.api/axios
	docker run --rm -v "${PWD}:/local" openapitools/openapi-generator-cli generate \
    	-i local/openapi-clickup.yml \
		-g typescript-aurelia \
		--skip-validate-spec \
    	-o local/.api/aurelia
	docker run --rm -v "${PWD}:/local" openapitools/openapi-generator-cli generate \
    	-i local/openapi-clickup.yml \
		-g typescript-jquery \
		--skip-validate-spec \
    	-o local/.api/jquery
	docker run --rm -v "${PWD}:/local" openapitools/openapi-generator-cli generate \
    	-i local/openapi-clickup.yml \
		-g typescript-inversify \
		--skip-validate-spec \
    	-o local/.api/inversify
	docker run --rm -v "${PWD}:/local" openapitools/openapi-generator-cli generate \
    	-i local/openapi-clickup.yml \
		-g typescript-nestjs \
		--skip-validate-spec \
    	-o local/.api/nestjs
	docker run --rm -v "${PWD}:/local" openapitools/openapi-generator-cli generate \
    	-i local/openapi-clickup.yml \
		-g typescript-rxjs \
		--skip-validate-spec \
    	-o local/.api/rxjs
	# docker-compose run --rm app npx openapi-generator-cli generate -g typescript-axios -i openapi-clickup.yml -o .api
	# @rm -rf .api

run:
	@docker exec -it clicknote-app-1 npm run format
	@docker exec -it clicknote-app-1 npm run dev

.DEFAULT_GOAL := help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-20s\033[0m %s\n", $$1, $$2}'
