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

init: ## プロジェクトを初期化する
	@ls -a | grep -xv -E '.git|.git/|.vscode|.vscode/|docker-compose.yml|Dockerfile|Makefile|.|./|..|../' | xargs rm -rf
	@rm .vscode/settings.json || true

	@docker exec -it clicknote-app-1 npm create vue@latest app

	@echo Move app project to root directory
	@mv app/.vscode/settings.json ./.vscode/
	@rm -rf app/.vscode
	@mv app/* .
	@mv app/.* .
	@rm -rf app
	@echo

	@echo npm install
	@docker exec -it clicknote-app-1 npm install
	@echo

	@echo npm run format
	@docker exec -it clicknote-app-1 npm run format

run:
	@docker exec -it clicknote-app-1 npm run format
	@docker exec -it clicknote-app-1 npm run dev

.DEFAULT_GOAL := help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-20s\033[0m %s\n", $$1, $$2}'
