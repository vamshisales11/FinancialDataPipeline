"""
BC003 | Silver → Gold Data Transformation Job (SCD Type 1, Delta Lake)
Author: Vamshi
Project: Scalable Financial Data Pipeline for Customer Analytics
Purpose:
    Transform clean Silver‑layer datasets into curated Gold‑layer tables.
    Implements SCD Type 1 (overwrite current snapshot fields) using Delta Lake
    in‑place merges for safe, ACID‑compliant updates.

    Outputs:
      1️⃣ Customer360     – unified customer profile
      2️⃣ LoanRisk        – loans + repayment analytics + risk signals
      3️⃣ Txn_Summary     – aggregated transaction KPIs
"""

import sys
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from delta.tables import DeltaTable   # built‑in in Glue 4 & 5

# ---------------------------------------------------------------------
# 1️⃣ Initialization
# ---------------------------------------------------------------------
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

print("✅ Glue job initialized and Spark session active.")

# ---------------------------------------------------------------------
# 2️⃣ Define Silver Data Inputs
# ---------------------------------------------------------------------
silver = "s3://bc003-silver-844840482726-us-east-1"
paths = {
    "customers":    f"{silver}/core_banking/customers/",
    "accounts":     f"{silver}/core_banking/accounts/",
    "loans":        f"{silver}/loan_mgmt/loans/",
    "loan_payments":f"{silver}/loan_mgmt/loan_payments/",
    "transactions": f"{silver}/transactions/"
}

print("🔹 Reading Silver datasets ...")
df_customers    = spark.read.parquet(paths["customers"])
df_accounts     = spark.read.parquet(paths["accounts"])
df_loans        = spark.read.parquet(paths["loans"])
df_loan_pymts   = spark.read.parquet(paths["loan_payments"])
df_transactions = spark.read.parquet(paths["transactions"])

# ---------------------------------------------------------------------
# 3️⃣ Sanity & Normalization
# ---------------------------------------------------------------------
df_customers    = df_customers.dropDuplicates(["customer_id"]).toDF(*[c.lower() for c in df_customers.columns])
df_accounts     = df_accounts.dropDuplicates(["account_id"]).toDF(*[c.lower() for c in df_accounts.columns])
df_loans        = df_loans.dropDuplicates(["loan_id"]).toDF(*[c.lower() for c in df_loans.columns])
df_loan_pymts   = df_loan_pymts.dropDuplicates(["payment_id"]).toDF(*[c.lower() for c in df_loan_pymts.columns])
df_transactions = df_transactions.dropDuplicates(["transaction_id"]).toDF(*[c.lower() for c in df_transactions.columns])

print("✅ Data normalization and deduplication complete.")

# ---------------------------------------------------------------------
# 4️⃣ Build Customer360 Dataset
# ---------------------------------------------------------------------
txn_summary_for_cust = (
    df_transactions.join(df_accounts, "account_id", "left")
    .groupBy("customer_id")
    .agg(
        F.countDistinct("transaction_id").alias("total_transactions"),
        F.round(F.sum("amount"), 2).alias("total_spent"),
        F.round(F.avg("amount"), 2).alias("avg_transaction_value"),
        F.countDistinct("merchant").alias("unique_merchants"),
        F.countDistinct("category").alias("unique_categories")
    )
)

acct_summary = (
    df_accounts.groupBy("customer_id")
    .agg(
        F.countDistinct("account_id").alias("num_accounts"),
        F.round(F.sum("balance"), 2).alias("total_balance"),
        F.collect_set("account_type").alias("account_types"),
        F.collect_set("branch_code").alias("branch_codes")
    )
)

customer360 = (
    df_customers
    .join(acct_summary, "customer_id", "left")
    .join(txn_summary_for_cust, "customer_id", "left")
    .fillna({
        "total_transactions": 0,
        "total_spent": 0.0,
        "avg_transaction_value": 0.0,
        "unique_merchants": 0,
        "unique_categories": 0,
        "num_accounts": 0,
        "total_balance": 0.0
    })
)

customer360 = customer360.withColumn(
    "financial_health_score",
    F.when(F.col("total_balance") > 10000, 5)
     .when(F.col("total_balance") > 5000, 4)
     .when(F.col("total_balance") > 1000, 3)
     .otherwise(2)
)
customer360 = customer360.withColumn("data_refresh_date", F.current_date())

print("✅ Customer360 dataset built successfully.")

# ---------------------------------------------------------------------
# 5️⃣ Build LoanRisk Analytics Dataset
# ---------------------------------------------------------------------
payment_summary = (
    df_loan_pymts.groupBy("loan_id")
    .agg(
        F.sum("amount_paid").alias("total_amount_paid"),
        F.sum("principal_component").alias("total_principal_paid"),
        F.sum("interest_component").alias("total_interest_paid"),
        F.countDistinct("payment_id").alias("num_payments")
    )
)

loan_risk = (
    df_loans.join(payment_summary, "loan_id", "left")
    .join(
        df_customers.select("customer_id", "income", "occupation", "city", "state", "country"),
        "customer_id",
        "left"
    )
    .fillna({
        "total_amount_paid": 0.0,
        "total_principal_paid": 0.0,
        "total_interest_paid": 0.0,
        "num_payments": 0
    })
)

loan_risk = (
    loan_risk
    .withColumn("outstanding_principal", F.col("principal_amount") - F.col("total_principal_paid"))
    .withColumn(
        "repayment_ratio",
        F.when(F.col("principal_amount") > 0,
               F.col("total_principal_paid") / F.col("principal_amount"))
         .otherwise(0)
    )
    .withColumn(
        "risk_flag",
        F.when(F.col("repayment_ratio") < 0.25, "High Risk")
         .when(F.col("repayment_ratio") < 0.75, "Medium Risk")
         .otherwise("Low Risk")
    )
    .withColumn("data_refresh_date", F.current_date())
)

print("✅ LoanRisk analytics dataset created successfully.")

# ---------------------------------------------------------------------
# 6️⃣ Build Txn_Summary Dataset
# ---------------------------------------------------------------------
txn_summary = (
    df_transactions.groupBy("transaction_type", "category")
    .agg(
        F.count("*").alias("txn_count"),
        F.round(F.sum("amount"), 2).alias("total_amount")
    )
    .withColumn("data_refresh_date", F.current_date())
)

print("✅ Transaction summary dataset created successfully.")

# ---------------------------------------------------------------------
# 7️⃣ Write Outputs to Gold Layer (SCD Type 1 in‑place merge)
# ---------------------------------------------------------------------
gold = "s3://bc003-gold-844840482726-us-east-1"

def scd1_merge(source_df, target_path, key_cols):
    """
    In‑place SCD Type 1 merge using Delta Lake.
    Updates fields for existing keys, inserts new rows, no schema changes.
    """
    try:
        delta_tbl = DeltaTable.forPath(spark, target_path)
        (
            delta_tbl.alias("t")
            .merge(source_df.alias("s"), " AND ".join([f"t.{k}=s.{k}" for k in key_cols]))
            .whenMatchedUpdateAll()
            .whenNotMatchedInsertAll()
            .execute()
        )
        print(f"✅ In‑place SCD1 merge completed for {target_path}")
    except Exception as e:
        print(f"⚙️ Creating new Delta table for {target_path}: {e}")
        (source_df
            .write
            .format("delta")
            .mode("overwrite")
            .partitionBy([c for c in source_df.columns if c in ("country", "category")])
            .save(target_path)
        )

print("📦 Performing in‑place SCD Type 1 merges for Gold datasets ...")

scd1_merge(customer360, f"{gold}/customer_360", ["customer_id"])
scd1_merge(loan_risk,   f"{gold}/loan_risk_analytics", ["loan_id"])
scd1_merge(txn_summary, f"{gold}/txn_summary", ["transaction_type", "category"])

# ---------------------------------------------------------------------
# 8️⃣ Commit
# ---------------------------------------------------------------------
job.commit()
print("✅ Silver → Gold transformation and SCD Type 1 merge completed successfully.")