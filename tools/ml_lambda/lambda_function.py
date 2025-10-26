import os, json, boto3, gzip, io, csv

s3 = boto3.client("s3")
cw = boto3.client("cloudwatch")
sns_arn = os.getenv("SNS_TOPIC_ARN", "")
THRESHOLD = float(os.getenv("THRESHOLD", "0.9"))
NAMESPACE = os.getenv("NAMESPACE", "BC003/ML")


def publish_metric(run_id, high_count, max_score):
    cw.put_metric_data(
        Namespace=NAMESPACE,
        MetricData=[
            {
                "MetricName": "HighScoreCount",
                "Dimensions": [{"Name": "RunId", "Value": run_id}],
                "Value": high_count,
                "Unit": "Count"
            },
            {
                "MetricName": "MaxScore",
                "Dimensions": [{"Name": "RunId", "Value": run_id}],
                "Value": max_score,
                "Unit": "None"
            },
        ]
    )


def notify_sns(bucket, key, high_count, max_score):
    if sns_arn:
        sns = boto3.client("sns")
        msg = {
            "bucket": bucket,
            "key": key,
            "high_count": high_count,
            "max_score": max_score,
            "threshold": THRESHOLD
        }
        sns.publish(TopicArn=sns_arn, Subject="BC003 ML High Scores", Message=json.dumps(msg))


def read_predictions(bucket, key):
    obj = s3.get_object(Bucket=bucket, Key=key)
    body = obj["Body"].read()
    if key.endswith(".gz"):
        body = gzip.GzipFile(fileobj=io.BytesIO(body)).read()

    text = body.decode("utf-8", errors="ignore").strip()
    scores = []

    # If JSON lines (common for RCF), parse {"score": ...}
    if text.startswith("{") or "\n{" in text:
        for line in text.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
                # accept either {"score": x} or {"scores":[x]} patterns
                if "score" in rec:
                    scores.append(float(rec["score"]))
                elif "scores" in rec and isinstance(rec["scores"], list) and rec["scores"]:
                    scores.append(float(rec["scores"][0]))
            except Exception:
                continue
        return scores

    # Else CSV (first column) or plain numeric lines
    if key.endswith(".csv") or "," in text:
        for row in csv.reader(io.StringIO(text)):
            if not row: continue
            try:
                scores.append(float(row[0]))
            except Exception:
                continue
    else:
        for line in text.splitlines():
            line = line.strip()
            if not line: continue
            try:
                scores.append(float(line))
            except Exception:
                pass

    return scores


def lambda_handler(event, context):
    # EventBridge S3 Object Created event
    detail = event.get("detail", {})
    bucket = detail.get("bucket", {}).get("name")
    key = detail.get("object", {}).get("key")
    if not bucket or not key:
        print("No bucket/key in event:", json.dumps(event))
        return {"ok": False, "reason": "no s3 object"}

    # RunId parsed from key: ml/predictions/<run_id>/...
    parts = key.split("/")
    run_id = "unknown"
    if len(parts) >= 3 and parts[0] == "ml" and parts[1] == "predictions":
        run_id = parts[2]

    scores = read_predictions(bucket, key)
    if not scores:
        print("No scores found in object", bucket, key)
        return {"ok": True, "count": 0}

    high = [s for s in scores if s >= THRESHOLD]
    high_count = len(high)
    max_score = max(scores)

    publish_metric(run_id, high_count, max_score)
    notify_sns(bucket, key, high_count, max_score)
    print(f"Processed {len(scores)} scores; high_count={high_count}, max={max_score}")
    return {"ok": True, "count": high_count, "max": max_score}

