import json
import os
import boto3

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
kinesis = boto3.client('kinesis')
secrets_manager = boto3.client('secretsmanager')

def handler(event, context):
    """
    Lambda function handler that demonstrates interaction with
    S3, DynamoDB, Kinesis, and Secrets Manager
    """
    try:
        # Get environment variables
        bucket_name = os.environ.get('S3_BUCKET_NAME')
        table_name = os.environ.get('DYNAMODB_TABLE')
        stream_name = os.environ.get('KINESIS_STREAM')
        secret_name = os.environ.get('SECRET_NAME')
        
        # Get secret from Secrets Manager
        secret_response = secrets_manager.get_secret_value(SecretId=secret_name)
        secret = json.loads(secret_response['SecretString'])
        
        # Put a record to Kinesis
        kinesis.put_record(
            StreamName=stream_name,
            Data=json.dumps({
                'message': 'Hello from Lambda',
                'timestamp': context.aws_request_id
            }),
            PartitionKey='lambda-partition'
        )
        
        # Write to DynamoDB
        table = dynamodb.Table(table_name)
        table.put_item(
            Item={
                'id': context.aws_request_id,
                'message': 'Lambda execution',
                'timestamp': str(context.aws_request_id)
            }
        )
        
        # Upload to S3 (optional, for demonstration)
        s3_key = f"lambda-outputs/{context.aws_request_id}.json"
        s3_client.put_object(
            Bucket=bucket_name,
            Key=s3_key,
            Body=json.dumps({
                'function_name': context.function_name,
                'request_id': context.aws_request_id,
                'message': 'Successfully processed'
            }),
            ContentType='application/json'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully processed',
                'request_id': context.aws_request_id,
                'bucket': bucket_name,
                'table': table_name,
                'stream': stream_name
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'request_id': context.aws_request_id
            })
        }

