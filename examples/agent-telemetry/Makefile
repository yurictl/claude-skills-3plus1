.PHONY: report html backfill seed reset

report:            ## console summary over the telemetry stores
	@python3 scripts/telemetry_report.py

html:              ## static dashboard -> .claude/telemetry/report.html
	@python3 scripts/telemetry_report.py --html .claude/telemetry/report.html

backfill:          ## harvest every transcript of this project (idempotent)
	@python3 scripts/telemetry_harvest.py --all

seed:              ## deterministic demo data (no real sessions needed)
	@python3 scripts/seed_demo.py

reset:             ## wipe the telemetry stores
	@rm -rf .claude/telemetry
	@echo "telemetry stores removed"
