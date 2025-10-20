# =====================================================================
#  BC003  |  Bronze → Silver Data Load Job
#  Purpose:  Read raw CSVs from Bronze, enforce strong schema & hygiene,
#             remove null/blank IDs, deduplicate, standardise case,
#             and land clean Parquet data into the Silver bucket.
# =====================================================================

import sys
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import functions as F, types as T

# ---------------------------------------------------------------------
# 1️⃣  Job and session setup
# ---------------------------------------------------------------------
args = getResolvedOptions(sys.argv, ["JOB_NAME", "BRONZE_BUCKET", "SILVER_BUCKET"])
bronze = args["BRONZE_BUCKET"]
silver = args["SILVER_BUCKET"]

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")

# ---------------------------------------------------------------------
# 2️⃣  Common helper functions
# ---------------------------------------------------------------------
def parse_date(col):
    """Safely convert various date formats to canonical yyyy-MM-dd."""
    return F.to_date(
        F.when(F.col(col).rlike("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"), F.col(col))
         .when(F.col(col).rlike("^[0-9]{2}-[0-9]{2}-[0-9]{2}$"), F.to_date(col, "dd-MM-yy"))
         .otherwise(None),
        "yyyy-MM-dd"
    )

def drop_key_nulls(df, cols):
    """Drop records where any of the key columns is null or blank."""
    for c in cols:
        df = df.filter((F.col(c).isNotNull()) & (F.trim(F.col(c)) != ""))
    return df

def clean_and_write(df, out_path, partition_col):
    """Write dataframe to Silver bucket (append mode, partitioned)."""
    (
        df.write
          .mode("append")
          .partitionBy(partition_col)
          .parquet(out_path)
    )

# =====================================================================
# 3️⃣  DATASET SECTIONS
# =====================================================================

# ---------------------------------------------------------------------
# CUSTOMERS — 0‑null IDs, typed numerics, clean text
# ---------------------------------------------------------------------
schema_customers = T.StructType([
    T.StructField("customer_id", T.StringType()),
    T.StructField("first_name", T.StringType()),
    T.StructField("last_name", T.StringType()),
    T.StructField("date_of_birth", T.StringType()),
    T.StructField("gender", T.StringType()),
    T.StructField("marital_status", T.StringType()),
    T.StructField("occupation", T.StringType()),
    T.StructField("income", T.StringType()),
    T.StructField("city", T.StringType()),
    T.StructField("state", T.StringType()),
    T.StructField("country", T.StringType()),
    T.StructField("join_date", T.StringType())
])

customers = (
    spark.read.option("header", "true").schema(schema_customers)
    .csv(f"s3://{bronze}/core_banking/ingest_date=*/customers.csv")
    .withColumn("date_of_birth", parse_date("date_of_birth"))
    .withColumn("join_date", parse_date("join_date"))
    .withColumn("income", F.col("income").cast("double"))
    .fillna({"income": 0.0, "gender": "Unknown", "marital_status": "Unknown"})
    .withColumn("first_name", F.initcap(F.trim(F.col("first_name"))))
    .withColumn("last_name", F.initcap(F.trim(F.col("last_name"))))
)
customers = drop_key_nulls(customers, ["customer_id"]).dropDuplicates(["customer_id"])
clean_and_write(customers, f"s3://{silver}/core_banking/customers/", "join_date")

# ---------------------------------------------------------------------
# ACCOUNTS — drop null IDs, normalise currency, dedup
# ---------------------------------------------------------------------
schema_accounts = T.StructType([
    T.StructField("account_id", T.StringType()),
    T.StructField("customer_id", T.StringType()),
    T.StructField("account_type", T.StringType()),
    T.StructField("branch_code", T.StringType()),
    T.StructField("balance", T.StringType()),
    T.StructField("currency", T.StringType()),
    T.StructField("open_date", T.StringType()),
    T.StructField("status", T.StringType())
])

accounts = (
    spark.read.option("header", "true").schema(schema_accounts)
    .csv(f"s3://{bronze}/core_banking/ingest_date=*/accounts.csv")
    .withColumn("open_date", parse_date("open_date"))
    .withColumn("balance", F.col("balance").cast("double"))
    .fillna({"currency": "USD", "status": "unknown"})
    .withColumn("account_type", F.lower(F.trim(F.col("account_type"))))
)
accounts = drop_key_nulls(accounts, ["account_id", "customer_id"]).dropDuplicates(["account_id"])
clean_and_write(accounts, f"s3://{silver}/core_banking/accounts/", "open_date")

# ---------------------------------------------------------------------
# LOANS — cleanse numerics, dates, remove blanks
# ---------------------------------------------------------------------
schema_loans = T.StructType([
    T.StructField("loan_id", T.StringType()),
    T.StructField("customer_id", T.StringType()),
    T.StructField("loan_type", T.StringType()),
    T.StructField("principal_amount", T.StringType()),
    T.StructField("interest_rate", T.StringType()),
    T.StructField("start_date", T.StringType()),
    T.StructField("end_date", T.StringType()),
    T.StructField("status", T.StringType())
])

loans = (
    spark.read.option("header", "true").schema(schema_loans)
    .csv(f"s3://{bronze}/loan_mgmt/ingest_date=*/loans.csv")
    .withColumn("principal_amount", F.col("principal_amount").cast("double"))
    .withColumn("interest_rate", F.col("interest_rate").cast("double"))
    .withColumn("start_date", parse_date("start_date"))
    .withColumn("end_date", parse_date("end_date"))
    .fillna({"status": "unknown"})
    .withColumn("loan_type", F.lower(F.trim(F.col("loan_type"))))
)
loans = drop_key_nulls(loans, ["loan_id", "customer_id"])
loans = loans.filter(F.col("principal_amount") >= 0).dropDuplicates(["loan_id"])
clean_and_write(loans, f"s3://{silver}/loan_mgmt/loans/", "start_date")

# ---------------------------------------------------------------------
# LOAN PAYMENTS — enforce numerics, drop missing IDs
# ---------------------------------------------------------------------
schema_payments = T.StructType([
    T.StructField("payment_id", T.StringType()),
    T.StructField("loan_id", T.StringType()),
    T.StructField("payment_date", T.StringType()),
    T.StructField("amount_paid", T.StringType()),
    T.StructField("principal_component", T.StringType()),
    T.StructField("interest_component", T.StringType()),
    T.StructField("payment_status", T.StringType())
])

payments = (
    spark.read.option("header", "true").schema(schema_payments)
    .csv(f"s3://{bronze}/loan_mgmt/ingest_date=*/loan_payments.csv")
    .withColumn("payment_date", parse_date("payment_date"))
    .withColumn("amount_paid", F.col("amount_paid").cast("double"))
    .withColumn("principal_component", F.col("principal_component").cast("double"))
    .withColumn("interest_component", F.col("interest_component").cast("double"))
    .fillna({"payment_status": "unknown"})
)
payments = drop_key_nulls(payments, ["payment_id", "loan_id"])
payments = payments.filter(F.col("amount_paid") > 0).dropDuplicates(["payment_id"])
clean_and_write(payments, f"s3://{silver}/loan_mgmt/loan_payments/", "payment_date")

# ---------------------------------------------------------------------
# TRANSACTIONS — clean and validate numeric amounts
# ---------------------------------------------------------------------
schema_txn = T.StructType([
    T.StructField("transaction_id", T.StringType()),
    T.StructField("account_id", T.StringType()),
    T.StructField("transaction_date", T.StringType()),
    T.StructField("transaction_type", T.StringType()),
    T.StructField("amount", T.StringType()),
    T.StructField("merchant", T.StringType()),
    T.StructField("category", T.StringType()),
    T.StructField("city", T.StringType()),
    T.StructField("country", T.StringType())
])

transactions = (
    spark.read.option("header", "true").schema(schema_txn)
    .csv(f"s3://{bronze}/txn_stream/batch/ingest_date=*/transactions.csv")
    .withColumn("transaction_date", parse_date("transaction_date"))
    .withColumn("amount", F.col("amount").cast("double"))
    .withColumn("transaction_type", F.lower(F.trim(F.col("transaction_type"))))
    .fillna({"category": "unknown", "merchant": "unknown"})
)
transactions = drop_key_nulls(transactions, ["transaction_id", "account_id"])
transactions = transactions.filter(F.col("amount") > 0).dropDuplicates(["transaction_id"])
clean_and_write(transactions, f"s3://{silver}/transactions/", "transaction_date")

# =====================================================================
# End of Job
# =====================================================================
print("✅  Bronze → Silver data load complete (append mode).")