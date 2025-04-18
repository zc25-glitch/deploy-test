# resource "kestra_namespace_file" "ingest" {
#   namespace = "eq-proj"
#   filename  = "ingest_data.py"
#   content   = file("../src/files/ingest_data.py")
# }

# resource "kestra_namespace_file" "schema" {
#   namespace = "eq-proj"
#   filename  = "api_extract_schema.py"
#   content   = file("../src/files/api_extract_schema.py")
# }

# resource "kestra_flow" "example" {
#   namespace = "eq-proj"
#   flow_id = "proj_api-to-bq-gcs-stg"
#   content = file("../src/flows/eq-proj_api-to-bq-gcs-stg.yml")
# }