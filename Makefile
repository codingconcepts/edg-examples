convert:
	@find . -name "*.yaml" | while read -r yaml; do \
		edg="$${yaml%.yaml}.edg"; \
		[ -f "$$edg" ] && continue; \
		if ! edg validate config --config "$$yaml" > /dev/null 2>&1; then \
			echo "SKIP (invalid yaml): $$yaml"; \
			continue; \
		fi; \
		edg convert "$$yaml" -o "$$edg"; \
		if ! edg validate config --config "$$edg" > /dev/null 2>&1; then \
			echo "FAIL (invalid edg): $$edg"; \
			rm -f "$$edg"; \
		fi; \
	done

teardown:
	- docker ps -aq | xargs docker rm -f