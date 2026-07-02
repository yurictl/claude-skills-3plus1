.PHONY: replay seed-violation reset

# Replay the golden set through a headless grader; prints catch-rate, fails on any miss.
replay:
	bash scripts/replay.sh

# Drop a violating manifest into app/k8s/ to demo the /review + hook loop.
seed-violation:
	cp tests/golden/latest-tag/case.yaml app/k8s/demo-violation.yaml
	@echo "Seeded app/k8s/demo-violation.yaml (image: nginx:latest)."
	@echo "Now ask Claude to commit & push it -> the hook blocks; run /review -> [BLOCKER]."

# Remove the demo violation and the grade marker.
reset:
	rm -f app/k8s/demo-violation.yaml .claude/grade-ok
	@echo "Clean."
