# sourced by julia_pod
#
# must define:
# - KUBERNETES_NAMESPACE
# - KUBERNETES_SERVICEACCOUNT
# - IMAGE_REPO -- a docker repo from which pod images can be pulled


# example setup

CALLER_ID=$(aws sts get-caller-identity)
AWS_ACCOUNT_ID=$(echo "$CALLER_ID" | jq -r .Account)
REGION="us-east-2"
PROJECT_NAME=$(echo "$CALLER_ID" | grep -oP 'assumed-role/\K[^/]*')

# above is setup for 3 required vars below

KUBERNETES_NAMESPACE="project-$PROJECT_NAME"
KUBERNETES_SERVICEACCOUNT="$PROJECT_NAME-service-account"
IMAGE_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${KUBERNETES_NAMESPACE}"
