# SageMaker Capabilities Demo
# Paste this into a SageMaker JupyterLab notebook cell

import sagemaker
import boto3
import pandas as pd
import numpy as np
from datetime import datetime, timezone
from sagemaker import get_execution_role

def step_start(name):
    now = datetime.now(timezone.utc)
    print(f"\n[{now.strftime('%H:%M:%S')}] === {name} ===")
    return now

def step_end(name, start):
    now = datetime.now(timezone.utc)
    elapsed = (now - start).total_seconds()
    print(f"[{now.strftime('%H:%M:%S')}] {name} completed in {elapsed:.1f}s")

demo_start = datetime.now(timezone.utc)

# --- 1. Environment Info ---
t = step_start("Environment Info")
session = sagemaker.Session()
role = get_execution_role()
region = session.boto_region_name
bucket = session.default_bucket()

print(f"Region:  {region}")
print(f"Role:    {role}")
print(f"Bucket:  {bucket}")
print(f"SDK ver: {sagemaker.__version__}")
step_end("Environment Info", t)

# --- 2. Generate synthetic customer churn dataset and upload to S3 ---
t = step_start("Data Generation & Upload")
np.random.seed(42)
n = 2000

account_age_months = np.random.randint(1, 72, n)
monthly_charges = np.random.uniform(20, 120, n)
support_tickets = np.random.poisson(2, n)
usage_minutes = np.random.exponential(300, n).astype(int)
contract_type = np.random.choice([0, 1, 2], n, p=[0.5, 0.3, 0.2])  # 0=month-to-month, 1=1yr, 2=2yr
num_products = np.random.randint(1, 6, n)

# Churn is more likely with: short tenure, high charges, many tickets, month-to-month
churn_score = (
    -0.03 * account_age_months
    + 0.02 * monthly_charges
    + 0.3 * support_tickets
    - 0.001 * usage_minutes
    - 0.8 * contract_type
    - 0.2 * num_products
    + np.random.randn(n) * 0.5
)
churned = (churn_score > np.percentile(churn_score, 73)).astype(int)

# Label MUST be the first column for SageMaker built-in XGBoost
data = pd.DataFrame({
    "churned": churned,
    "account_age_months": account_age_months,
    "monthly_charges": monthly_charges,
    "support_tickets": support_tickets,
    "usage_minutes": usage_minutes,
    "contract_type": contract_type,
    "num_products": num_products,
})

print(f"Scenario: Predict whether a telecom customer will cancel their subscription.")
print(f"  {n} customers, {churned.sum()} churned ({churned.mean():.1%} churn rate)\n")
print(f"Features:")
print(f"  account_age_months  - How long the customer has been subscribed (1-72 months)")
print(f"  monthly_charges     - Monthly bill amount ($20-$120)")
print(f"  support_tickets     - Number of support tickets filed (avg ~2)")
print(f"  usage_minutes       - Monthly service usage in minutes")
print(f"  contract_type       - 0=month-to-month, 1=one-year, 2=two-year")
print(f"  num_products        - Number of subscribed products (1-5)\n")
print(f"Churn drivers: short tenure, high charges, many tickets, month-to-month contracts")
print(f"\n{data.describe().round(2).to_string()}")

train = data.sample(frac=0.8, random_state=1)
test = data.drop(train.index)

train_path = "/tmp/train.csv"
test_path = "/tmp/test.csv"
train.to_csv(train_path, index=False, header=False)
test.to_csv(test_path, index=False, header=False)

prefix = "sagemaker-demo"
train_s3 = session.upload_data(train_path, bucket=bucket, key_prefix=f"{prefix}/train")
test_s3 = session.upload_data(test_path, bucket=bucket, key_prefix=f"{prefix}/test")
print(f"\nTrain: {train_s3} ({len(train)} rows)")
print(f"Test:  {test_s3} ({len(test)} rows)")
step_end("Data Generation & Upload", t)

# --- 3. Train with the built-in XGBoost algorithm ---
t = step_start("Training Job")
from sagemaker.inputs import TrainingInput
from sagemaker.image_uris import retrieve

container = retrieve("xgboost", region, version="1.5-1")

xgb = sagemaker.estimator.Estimator(
    image_uri=container,
    role=role,
    instance_count=1,
    instance_type="ml.m5.large",
    output_path=f"s3://{bucket}/{prefix}/output",
    sagemaker_session=session,
    max_run=600,
)

xgb.set_hyperparameters(
    objective="binary:logistic",
    num_round=100,
    max_depth=5,
    eta=0.2,
    eval_metric="auc",
)

xgb.fit({
    "train": TrainingInput(train_s3, content_type="text/csv"),
    "validation": TrainingInput(test_s3, content_type="text/csv"),
})
step_end("Training Job", t)

# --- 4. Deploy a real-time endpoint ---
t = step_start("Endpoint Deployment")
predictor = xgb.deploy(
    initial_instance_count=1,
    instance_type="ml.m5.large",
    serializer=sagemaker.serializers.CSVSerializer(),
    deserializer=sagemaker.deserializers.CSVDeserializer(),
)
print(f"Endpoint: {predictor.endpoint_name}")
step_end("Endpoint Deployment", t)

# --- 5. Run inference ---

# Batch prediction
t = step_start("Batch Inference")
test_features = test.drop(columns=["churned"]).values
predictions = predictor.predict(test_features)
actuals = test["churned"].values

probs = [float(row[0]) for row in predictions]
preds = [1 if p >= 0.5 else 0 for p in probs]
correct = sum(p == a for p, a in zip(preds, actuals))

print(f"{len(actuals)} test customers scored")
for i in range(min(10, len(actuals))):
    prob = probs[i]
    label = "CHURNED" if actuals[i] else "stayed"
    verdict = "✓" if preds[i] == actuals[i] else "✗"
    row = test.iloc[i]
    print(f"  {verdict} Customer {i}: churn_prob={prob:.3f}  actual={label}"
          f"  (tenure={int(row['account_age_months'])}mo, ${row['monthly_charges']:.0f}/mo, {int(row['support_tickets'])} tickets)")
print(f"  ... ({len(actuals) - 10} more)")

tp = sum(1 for p, a in zip(preds, actuals) if p == 1 and a == 1)
fp = sum(1 for p, a in zip(preds, actuals) if p == 1 and a == 0)
tn = sum(1 for p, a in zip(preds, actuals) if p == 0 and a == 0)
fn = sum(1 for p, a in zip(preds, actuals) if p == 0 and a == 1)
print(f"\n  Overall accuracy: {correct}/{len(actuals)} ({correct/len(actuals):.1%})")
print(f"  Confusion matrix:  TP={tp}  FP={fp}  TN={tn}  FN={fn}")
if (tp+fp) and (tp+fn):
    print(f"  Precision: {tp/(tp+fp):.1%}  Recall: {tp/(tp+fn):.1%}")
step_end("Batch Inference", t)

# Hypothetical customer scenarios
t = step_start("Hypothetical Scenarios")
scenarios = [
    # [account_age, monthly_charges, support_tickets, usage_min, contract_type, num_products]
    ("New, expensive, month-to-month",   [3,  110, 5, 100, 0, 1]),
    ("Loyal, cheap, 2-year contract",    [60,  30, 0, 500, 2, 4]),
    ("Mid-tenure, moderate, 1-year",     [24,  65, 2, 300, 1, 2]),
    ("New, cheap, many products",        [2,   25, 1, 400, 0, 5]),
    ("Long tenure, high charges, angry", [48, 115, 8, 150, 1, 1]),
]

for desc, features in scenarios:
    pred = predictor.predict([features])
    prob = float(pred[0][0])
    risk = "HIGH" if prob >= 0.7 else "MEDIUM" if prob >= 0.4 else "LOW"
    print(f"  {risk:6s} ({prob:.1%}) - {desc}")
step_end("Hypothetical Scenarios", t)

# Single real-time prediction
t = step_start("Single Real-Time Prediction")
single = [6, 95, 4, 80, 0, 1]  # new customer, high charges, several tickets
pred = predictor.predict([single])
prob = float(pred[0][0])
print(f"  Customer profile: 6mo tenure, $95/mo, 4 tickets, 80min usage, month-to-month, 1 product")
print(f"  Churn probability: {prob:.1%}")
step_end("Single Real-Time Prediction", t)

# --- 6. Explore resources before cleanup ---
total_elapsed = (datetime.now(timezone.utc) - demo_start).total_seconds()
print(f"\n{'='*60}")
print(f"Total demo time: {total_elapsed/60:.1f} minutes ({total_elapsed:.0f}s)")
print(f"{'='*60}")

print(f"\n=== Resources to explore in the SageMaker Console ===")
print(f"  Training job:  {xgb.latest_training_job.name}")
print(f"  Model:         {predictor.endpoint_name}")
print(f"  Endpoint:      {predictor.endpoint_name}")
print(f"  S3 artifacts:  s3://{bucket}/{prefix}/")
print(f"\nConsole link: https://{region}.console.aws.amazon.com/sagemaker/home?region={region}#/endpoints")

input("\n⏸  Press Enter to delete the endpoint and clean up (it costs money while running!)...")

t = step_start("Cleanup")
predictor.delete_endpoint()
step_end("Cleanup", t)
print("Done! Model artifacts remain at:")
print(f"  s3://{bucket}/{prefix}/output/")
