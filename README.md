"# FinancialDataPipeline\n\nThis repository contains AWS Glue job scripts and Infrastructure as Code for the financial data pipeline project.\n\nFolders:\n- glue_jobs/: AWS Glue scripts\n- iac/: Infrastructure as Code scripts\n\nRefer to this README for setup instructions." 


"# BC003 Financial Data Pipeline (AWS)

Layers:
- Bronze (ingestion): S3 raw, DataSync (batch), Firehose (real-time)
- Silver (cleaned): Glue PySpark (schemas, dedupe, null rules), Parquet
- Gold (analytics): Delta Lake on S3, SCD Type 1, marts (Customer360, LoanRisk)
- Analytics: Athena, Redshift
- Governance: Lake Formation
- Monitoring: CloudWatch + Glue DQ

Repo layout:
- glue_jobs/: PySpark code (silver, gold, dq, lib)
- iac/terraform/: Terraform (modules per layer)
- configs/: mapping + DQ rule configs
- data_dictionary/: business-facing data dictionary
- docs/: architecture diagram + screenshots
- scripts/: helper scripts (e.g., Firehose generator)
- sql/: saved queries (Athena/Redshift)
- tests/: unit tests

Status: scaffold only; no AWS resources created yet."