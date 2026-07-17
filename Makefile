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

validate:
	@included=$$(grep -rh "^include " --include="*.edg" . 2>/dev/null | sed "s/include '//;s/'.*//"); \
	find . -name "*.edg" -not -path "*/includes/shared/*" -not -path "*/includes/output/*" -not -path "*/capture/output/*" -not -path "*/plugins/*" -not -path "*/correlated_signals/*" | sort | while read -r edg; do \
		base=$$(basename "$$edg"); \
		echo "$$included" | grep -qxF "$$base" && continue; \
		if ! edg validate config --config "$$edg" > /dev/null 2>&1; then \
			echo "FAIL: $$edg"; \
		fi; \
	done

doctor:
	@included=$$(grep -rh "^include " --include="*.edg" . 2>/dev/null | sed "s/include '//;s/'.*//"); \
	find . -name "*.edg" -not -path "*/includes/shared/*" -not -path "*/includes/output/*" -not -path "*/capture/output/*" -not -path "*/plugins/*" -not -path "*/correlated_signals/*" | sort | while read -r edg; do \
		base=$$(basename "$$edg"); \
		echo "$$included" | grep -qxF "$$base" && continue; \
		output=$$(edg doctor --config "$$edg" 2>&1); \
		if [ "$$output" != "No issues found." ]; then \
			echo "--- $$edg ---"; \
			echo "$$output"; \
		fi; \
	done

teardown:
	- docker ps -aq | xargs docker rm -f