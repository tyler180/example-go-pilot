data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = ["arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.this.account_id}:function:${local.name}"]
  }
}