# ──────────────────────────────────────────────────────────────────────────────
# Generic IAM Policy + Role attachment
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_iam_policy" "this" {
  name   = var.policy_name
  policy = var.policy_json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = var.role_name
  policy_arn = aws_iam_policy.this.arn
}
