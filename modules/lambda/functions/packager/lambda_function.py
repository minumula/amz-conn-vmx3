current_version = '2025.09.13'
'''
**********************************************************************************************************************
 *  Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved                                            *
 *                                                                                                                    *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated      *
 *  documentation files (the "Software"), to deal in the Software without restriction, including without limitation   *
 *  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and  *
 *  to permit persons to whom the Software is furnished to do so.                                                     *
 *                                                                                                                    *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO  *
 *  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    *
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF         *
 *  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS *
 *  IN THE SOFTWARE.                                                                                                  *
 **********************************************************************************************************************
'''

import boto3
import json
import logging
import os

logger = logging.getLogger()

def lambda_handler(event, context):
    logger.debug('Function Name: ' + os.environ['AWS_LAMBDA_FUNCTION_NAME'])
    logger.debug('Code Version: ' + current_version)
    logger.debug('VMX3 Package Version: ' + os.environ['package_version'])
    logger.debug('********** Beginning Voicemail Packager **********')
    logger.debug(event)
    
    if event['detail']['object']['key'].endswith('.write_access_check_file.temp'):
        logger.info('********** WRITE TEST - IGNORE **********')
        return('********** WRITE TEST - IGNORE **********')

    s3_client = boto3.client('s3')
    transcribe_client = boto3.client('transcribe')
    connect_client = boto3.client('connect')
    lambda_client = boto3.client('lambda')
    sns_client = boto3.client('sns')
    logger.debug('********** Initialization Complete **********')

    # Get transcript data
    transcript_key = event['detail']['object']['key']
    transcript_bucket = event['detail']['bucket']['name']
    contact_id = transcript_key.rsplit('/',1)[1].replace('.json','')
    
    transcript_obj = s3_client.get_object(Bucket=transcript_bucket, Key=transcript_key)
    transcript_data = json.loads(transcript_obj['Body'].read().decode('utf-8'))
    
    transcript_text = transcript_data['results']['transcripts'][0]['transcript']
    logger.info(f'********** Transcript retrieved for contact {contact_id} **********')
    logger.debug(f'Transcript: {transcript_text}')

    # Get recording metadata
    recording_key = transcript_key.replace('.json', '.wav')
    recording_bucket = os.environ['s3_recordings_bucket']
    
    recording_tags = s3_client.get_object_tagging(Bucket=recording_bucket, Key=recording_key)
    tags_dict = {tag['Key']: tag['Value'] for tag in recording_tags['TagSet']}
    
    instance_id = tags_dict['vmx3_queue_arn'].split('/')[1]

    customer_response= connect_client.describe_contact(
        InstanceId = instance_id,
        ContactId = contact_id
    )
    customer_phone = customer_response['Contact']['CustomerEndpoint']['Address']

    logger.debug(f'********** Retrieved metadata - Instance: {instance_id} **********')

    # Invoke presigner to get presigned URL
    try:
        input_params = {
            'recording_bucket': recording_bucket,
            'recording_key': recording_key
        }

        presigner_response = lambda_client.invoke(
            FunctionName = os.environ['presigner_function_arn'],
            InvocationType = 'RequestResponse',
            Payload = json.dumps(input_params)
        )

        response_from_presigner = json.load(presigner_response['Payload'])
        presigned_url = response_from_presigner['presigned_url']
        logger.debug('********** Presigner Completed **********')
    except Exception as e:
        logger.error('********** Failed to generate presigned URL **********')
        logger.error(e)
        presigned_url = 'https://github.com/amazon-connect/voicemail-express-amazon-connect'

    # Send SNS notification with transcript and presigned URL
    try:
        sns_topic_arn = os.environ['sns_topic_arn']
        
        message = f"""
New Voicemail Received

Contact ID: {contact_id}

Queue ARN: {tags_dict.get('vmx3_queue_arn', 'N/A')}

Phone: {customer_phone}

Transcript:
{transcript_text}

Recording URL: https://cruz-connect.govcloud.connect.aws/contact-trace-records/details/{contact_id}?tz=America/New_York
"""
#         Recording URL (expires in {os.environ.get('url_expire_days', '7')} days):
# {presigned_url}

        sns_client.publish(
            TopicArn=sns_topic_arn,
            # Subject=f'Voicemail - Contact {contact_id}',
            Subject=f'Voicemail - Phone Number {customer_phone} - {contact_id}',
            Message=message
        )
        logger.info('********** SNS notification sent **********')
    except Exception as e:
        logger.error('********** Failed to send SNS notification **********')
        logger.error(e)

    # Delete transcription job
    try:
        transcribe_client.delete_transcription_job(
            TranscriptionJobName='vmx3_' + contact_id
        )
        logger.debug('********** Transcribe Job Deleted **********')
    except Exception as e:
        logger.error('********** Failed to delete transcription job **********')
        logger.error(e)

    # Clear vmx3_flag
    try:
        connect_client.update_contact_attributes(
            InitialContactId=contact_id,
            InstanceId=instance_id,
            Attributes={'vmx3_flag': '0'}
        )
        logger.debug('********** vmx3_flag cleared for contact **********')
    except Exception as e:
        logger.error('********** Failed to clear vmx3_flag **********')
        logger.error(e)

    logger.info('********** Voicemail processing complete **********')
    return {'status':'complete','result':'success'}
