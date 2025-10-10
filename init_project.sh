#!/bin/bash

mkdir -p glue_jobs/{silver,gold,dq,lib}
mkdir -p iac/terraform/modules/{foundation,bronze,silver,gold,lakeformation,athena,redshift,monitoring}
mkdir -p configs data_dictionary docs/screenshots scripts sql/{athena,redshift} tests/unit

touch glue_jobs/silver/README.md \
      glue_jobs/gold/README.md \
      glue_jobs/dq/README.md \
      glue_jobs/lib/bc003_common.py \
      iac/terraform/main.tf \
      iac/terraform/variables.tf \
      iac/terraform/outputs.tf \
      iac/terraform/modules/foundation/README.md \
      iac/terraform/modules/bronze/README.md \
      iac/terraform/modules/silver/README.md \
      iac/terraform/modules/gold/README.md \
      iac/terraform/modules/lakeformation/README.md \
      iac/terraform/modules/athena/README.md \
      iac/terraform/modules/redshift/README.md \
      iac/terraform/modules/monitoring/README.md \
      configs/BC003_Mappings_Customers.yaml \
      configs/BC003_Mappings_Transactions.yaml \
      configs/BC003_DQ_Rules_Transactions.yaml \
      data_dictionary/BC003_DataDictionary.md \
      docs/README.md \
      scripts/README.md \
      sql/athena/README.md \
      sql/redshift/README.md \
      tests/unit/test_placeholder.py \
      .gitignore
echo "Project structure initialized."
