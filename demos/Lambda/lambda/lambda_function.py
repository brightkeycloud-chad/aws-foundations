import time

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': str(int(time.time()))
    }
