.PHONY: upload clean-logs help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  make %-15s %s\n", $$1, $$2}'

upload: ## Upload packages (usage: make upload [SRC=path])
	bash pip_upload_script.sh $(SRC)

clean-logs: ## Remove all upload log files
	rm -f upload_*.log
