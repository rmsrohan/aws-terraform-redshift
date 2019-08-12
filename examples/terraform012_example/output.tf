###############################################################################
# Outputs
# terraform output summary
###############################################################################

output "summary" {
  value = <<EOF
## Outputs
| db_port                       | ${module.redshift_test.db_port} |
| jdbc_connection_string        | ${module.redshift_test.jdbc_connection_string} |
| redshift_address              | ${module.redshift_test.redshift_address} |
| redshift_cluster_identifier   | ${module.redshift_test.redshift_cluster_identifier} |
EOF
  description = "redshift output summary"
}
