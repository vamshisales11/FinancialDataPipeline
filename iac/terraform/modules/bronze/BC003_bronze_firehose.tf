resource "aws_kinesis_firehose_delivery_stream" "transactions" {
  # Use no-tags provider to avoid TagDeliveryStream (optional but recommended if you hit IAM errors)
  provider = aws.notags

  name        = local.firehose_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bronze.arn

    buffering_interval = 60
    buffering_size     = 5
    compression_format = "UNCOMPRESSED"

    # Data prefix (keeps your ingest_date partitioning)
    prefix = "txn_stream/ingest_date=!{timestamp:yyyy-MM-dd}/"

    # REQUIRED: include !{firehose:error-output-type}
    error_output_prefix = "txn_stream/errors/!{firehose:error-output-type}/ingest_date=!{timestamp:yyyy-MM-dd}/"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/${local.firehose_name}"
      log_stream_name = "S3Delivery"
    }
  }
}