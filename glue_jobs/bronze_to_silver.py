#Script — reads actual CSV headers, enforces schema, dedupes, handles nulls & writes Parquet to Silver

import sys
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import functions as F, types as T

# ---------- read job arguments ----------
args = getResolvedOptions(sys.argv, ["JOB_NAME", "BRONZE_BUCKET", "SILVER_BUCKET"])
bronze = args["BRONZE_BUCKET"]
silver = args["SILVER_BUCKET"]

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# ---------- helpers ----------
def parse_date(col):
    """Convert dd-MM-yy strings safely to yyyy-MM-dd dates."""
    return F.to_date(F.when(F.length(col) == 8, F.to_date(col, "dd-MM-yy")).otherwise(None))

def clean_and_write(df, out_path, partition_col):
    """Write cleaned dataframe to parquet in silver."""
    (df.write
       .mode("overwrite")
       .partitionBy(partition_col)
       .parquet(out_path))

# ------------------------------------------------------------------
# 1️⃣  CUSTOMERS
# ------------------------------------------------------------------
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

customers = (spark.read.option("header", "true").schema(schema_customers)
    .csv(f"s3://{bronze}/core_banking/ingest_date=*/customers.csv")
    .withColumn("date_of_birth", parse_date(F.col("date_of_birth")))
    .withColumn("join_date", parse_date(F.col("join_date")))
    .withColumn("income", F.col("income").cast("double"))
    .fillna({"marital_status": "Unknown", "gender": "Unknown", "income": 0.0})
    .dropDuplicates(["customer_id"])
)
clean_and_write(customers, f"s3://{silver}/core_banking/customers/", "join_date")

# ------------------------------------------------------------------
# 2️⃣  ACCOUNTS
# ------------------------------------------------------------------
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

accounts = (spark.read.option("header", "true").schema(schema_accounts)
    .csv(f"s3://{bronze}/core_banking/ingest_date=*/accounts.csv")
    .withColumn("open_date", parse_date(F.col("open_date")))
    .withColumn("balance", F.col("balance").cast("double"))
    .fillna({"currency": "USD"})
    .dropDuplicates(["account_id"])
)
clean_and_write(accounts, f"s3://{silver}/core_banking/accounts/", "open_date")

# ------------------------------------------------------------------
# 3️⃣  LOANS
# ------------------------------------------------------------------
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

loans = (spark.read.option("header", "true").schema(schema_loans)
    .csv(f"s3://{bronze}/loan_mgmt/ingest_date=*/loans.csv")
    .withColumn("principal_amount", F.col("principal_amount").cast("double"))
    .withColumn("interest_rate", F.col("interest_rate").cast("double"))
    .withColumn("start_date", parse_date(F.col("start_date")))
    .withColumn("end_date", parse_date(F.col("end_date")))
    .dropDuplicates(["loan_id"])
)
clean_and_write(loans, f"s3://{silver}/loan_mgmt/loans/", "start_date")

# ------------------------------------------------------------------
# 4️⃣  LOAN PAYMENTS
# ------------------------------------------------------------------
schema_payments = T.StructType([
    T.StructField("payment_id", T.StringType()),
    T.StructField("loan_id", T.StringType()),
    T.StructField("payment_date", T.StringType()),
    T.StructField("amount_paid", T.StringType()),
    T.StructField("principal_component", T.StringType()),
    T.StructField("interest_component", T.StringType()),
    T.StructField("payment_status", T.StringType())
])

payments = (spark.read.option("header", "true").schema(schema_payments)
    .csv(f"s3://{bronze}/loan_mgmt/ingest_date=*/loan_payments.csv")
    .withColumn("payment_date", parse_date(F.col("payment_date")))
    .withColumn("amount_paid", F.col("amount_paid").cast("double"))
    .withColumn("principal_component", F.col("principal_component").cast("double"))
    .withColumn("interest_component", F.col("interest_component").cast("double"))
    .fillna({"payment_status": "Unknown"})
    .dropDuplicates(["payment_id"])
)
clean_and_write(payments, f"s3://{silver}/loan_mgmt/loan_payments/", "payment_date")

# ------------------------------------------------------------------
# 5️⃣  TRANSACTIONS
# ------------------------------------------------------------------
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

txn = (spark.read.option("header", "true").schema(schema_txn)
    .csv(f"s3://{bronze}/txn_stream/batch/ingest_date=*/transactions.csv")
    .withColumn("transaction_date", parse_date(F.col("transaction_date")))
    .withColumn("amount", F.col("amount").cast("double"))
    .dropDuplicates(["transaction_id"])
)
clean_and_write(txn, f"s3://{silver}/transactions/", "transaction_date")