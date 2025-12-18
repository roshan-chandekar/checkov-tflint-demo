output "stream_name" {
  description = "Kinesis stream name"
  value       = aws_kinesis_stream.stream.name
}

output "stream_arn" {
  description = "Kinesis stream ARN"
  value       = aws_kinesis_stream.stream.arn
}

output "stream_id" {
  description = "Kinesis stream ID"
  value       = aws_kinesis_stream.stream.id
}

