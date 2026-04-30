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
from datetime import datetime

logger = logging.getLogger()

def lambda_handler(event, context):
    logger.debug('Function Name: ' + os.environ['AWS_LAMBDA_FUNCTION_NAME'])
    logger.debug('Code Version: ' + current_version)
    logger.debug('VMX3 Package Version: ' + os.environ['package_version'])
    logger.debug('********** Beginning Voicemail Packager **********')
    logger.info(event)

    # 1. Initialization: Process the incoming event, filter write checks, establish clients
    try:
        # Establish empty containers
        function_response = {} # for the response
        function_payload = {} # for passing data to sub functions
        function_payload.update({'vmx_data':{}})
        function_payload.update({'function_data':{}})
        
        # Filter out write checks
        if event['detail']['object']['key'].endswith('.write_access_check_file.temp'):
            logger.info('********** WRITE TEST - IGNORE **********')
            return('********** WRITE TEST - IGNORE **********')

        # Establish required clients
        s3_client = boto3.client('s3')
        s3_resource = boto3.resource('s3')
        transcribe_client = boto3.client('transcribe')
        connect_client = boto3.client('connect')
        lambda_client = boto3.client('lambda')
        sns_client = boto3.client('sns')

        logger.debug('********** Initialization Complete **********')
        logger.info('********** Voicemail Packager Step 1 of 6 Initialization of Clients & Containers complete **********')
    
    except Exception as e:
        logger.error('********** Initialization Failed **********')
        logger.info('********** Voicemail Packager Step 1 of 6 Initialization of Clients & Containers failed **********')
        logger.error(e)
        raise Exception    

    # 2. Gather Voicemail Data for packaging
    # Get transcript data
    try:
        transcript_key = event['detail']['object']['key']
        transcript_bucket = event['detail']['bucket']['name']
        transcript_file_name = transcript_key.rsplit('/',1)[1]
        contact_id = transcript_key.rsplit('/',1)[1].replace('.json','')
        
        # transcript_obj = s3_client.get_object(Bucket=transcript_bucket, Key=transcript_key)
        # transcript_data = json.loads(transcript_obj['Body'].read().decode('utf-8'))
        # transcript_text = transcript_data['results']['transcripts'][0]['transcript']

        logger.debug(f'********** Transcript retrieved for contact {contact_id} **********')
        # logger.info('********** Sub: Key Data Extraction Step 1 of 5 Core Attributes Line 75 **********')

        # Get recording metadata
        recording_key = transcript_key.replace('.json', '.wav')
        recording_bucket = os.environ['s3_recordings_bucket']
        
        recording_tags = s3_client.get_object_tagging(Bucket=recording_bucket, Key=recording_key)
        tags_dict = {tag['Key']: tag['Value'] for tag in recording_tags['TagSet']}
        
        instance_id = tags_dict['vmx3_queue_arn'].split('/')[1]

        # logger.info('********** Sub: Key Data Extraction Step 1 of 5 Core Attributes Line 86 **********')

        customer_response= connect_client.describe_contact(
            InstanceId = instance_id,
            ContactId = contact_id
        )
        customer_phone = customer_response['Contact']['CustomerEndpoint']['Address']


        # logger.info('********** Sub: Key Data Extraction Step 1 of 5 Core Attributes Line 97 **********')
        
        function_payload['function_data'].update({'transcript_bucket':transcript_bucket, 'recording_bucket':recording_bucket})
        function_payload['function_data'].update({'transcript_key':transcript_key,'transcript_file_name':transcript_file_name,'recording_key':recording_key})
        function_payload['function_data'].update({'contact_id':contact_id})

        # logger.info('********** Sub: Key Data Extraction Step 1 of 5 Core Attributes Line 103 **********')

        transcript_object = s3_resource.Object(function_payload['function_data']['transcript_bucket'], function_payload['function_data']['transcript_key'])
        file_content = transcript_object.get()['Body'].read().decode('utf-8')
        json_content = json.loads(file_content)
        vmx3_transcript_contents = json_content['results']['transcripts'][0]['transcript']
        function_payload['function_data'].update({'vmx3_transcript_contents':vmx3_transcript_contents})

        #function_payload['function_data'].update({'vmx3_transcript_contents':transcript_text})

        logger.info('********** Sub: Key Data Extraction Step 1 of 5 Core Attributes Complete **********')

    except Exception as e:
        logger.info('********** Sub: Key Data Extraction Step 1 of 5 - Failed to extract core attributes **********')
        logger.error(e)
        raise Exception 

    try:
        s3_client = boto3.client('s3')

        object_data = s3_client.get_object_tagging(
            Bucket = recording_bucket,
            Key = recording_key
        )

        object_tags = object_data['TagSet']
        loaded_tags = {}

        for i in object_tags:
            loaded_tags.update({i['Key']:i['Value']})
        
        logger.info('********** Sub: Key Data Extraction Step 2 of 5 Tag Extraction Complete **********')

    except Exception as e:
        logger.info('********** Sub: Key Data Extraction Step 2 of 5 - Record Result: Failed to extract tags **********')
        logger.error(e)
        raise Exception

    # Set attributes from tags
    try:
        queue_arn = loaded_tags['vmx3_queue_arn']
        arn_substring = queue_arn.split('instance/')[1]
        instance_id = arn_substring.split('/queue')[0]
        function_payload['function_data'].update({'instance_id':instance_id})

        queue_id = arn_substring.split('queue/')[1]
        function_payload['function_data'].update({'queue_id':queue_id})
        logger.info('********** Sub: Key Data Extraction Step 3 of 5 - Instance attributes set **********')

    except Exception as e:
        logger.info('********** Sub: Key Data Extraction Step 3 fo 5 - Failed to set instance attributess **********')
        logger.error(e)
        raise Exception

    # Get the current date and time in UTC using timezone-aware objects
    
    try:
        current_datetime = datetime.now()
        formatted_datetime = current_datetime.strftime("%A, %b %d at %I:%M %p (Instance Time)")
        function_payload['vmx_data'].update({'vmx3_datetime':formatted_datetime})
        logger.debug('Processed Timestamp: ' + formatted_datetime)
        logger.info('********** Sub: Key Data Extraction Step 4 of 5 - Timestamp set **********')
    
    except Exception as e:
        logger.info('********** Sub: Key Data Extraction Step 4 of 5 - Failed to get timestamp **********')
        logger.error(e)
        
        formatted_datetime = 'UNKNOWN'
        function_payload['vmx_data'].update({'vmx3_datetime':formatted_datetime})

    try:
        contact_attributes = connect_client.get_contact_attributes(
            InstanceId = instance_id,
            InitialContactId = contact_id
        )
        original_contact_attributes = contact_attributes['Attributes']

        # Add the VMX3 keys to the vmx_data container
        for key, value in original_contact_attributes.items():
            if key.startswith('vmx3_'):
                function_payload['vmx_data'].update({key:value})

        # Pop the VMX3 keys from the original_contact_attributes container
        for key in list(original_contact_attributes.keys()):
            if key.startswith('vmx3_'):
                original_contact_attributes.pop(key)

        function_payload.update({'original_contact_attributes':original_contact_attributes})
        logger.info('********** Sub: Key Data Extraction Step 5 of 5 - Contact attributes for voicemail set **********')
        logger.info('********** Voicemail Packager Step 2 of 6 Key Data Extraction Complete **********')

    except Exception as e:
        logger.info('********** Sub: Key Data Extraction Step 5 of 5 - Failed to get contact attributes for voicemail **********')
        logger.info('********** Voicemail Packager Step 2 of 6 Key Data Extraction failed **********')
        logger.error(e)
        raise Exception


    #3. Build Data Payload with Transcript and Queue Details
    try:
        #function_payload['function_data'].update({'vmx3_transcript_contents':transcript_text})
        function_payload['function_data'].update({'vmx3_transcript_contents':vmx3_transcript_contents})
        logger.info('********** Sub:Process Transcription Step 1 of 2 - Retrieved transcript from S3 **********')

    except Exception as e:
        logger.info('********** Sub:Process Transcription Step 1 of 2 - Failed to retrieve transcript from S3 **********')
        logger.error(e)
        raise Exception

    try:
        logger.debug('********** Queue Setup **********')
        # Grab Queue info
        get_queue_details = connect_client.describe_queue(
            InstanceId=function_payload['function_data']['instance_id'],
            QueueId=function_payload['function_data']['queue_id']
        )

        vmx3_queue_name = get_queue_details['Queue']['Name']
        vmx3_queue_arn = get_queue_details['Queue']['QueueArn']
        function_payload['vmx_data'].update({'vmx3_queue_name':vmx3_queue_name,'vmx3_queue_arn':vmx3_queue_arn})
        logger.info('********** Sub:Record Result Step 2 of 2: Queue details extracted **********')
        logger.info('********** Voicemail Packager Step 3 of 6 Queue details Complete **********')

    except Exception as e:
        logger.info('********** Sub:Record Result Step 2 of 2: Failed to extract queue details **********')
        logger.info('********** Voicemail Packager Step 3 of 6 Failed Queue details Complete **********')
        logger.error(e)
        
        vmx3_queue_name = 'UNKNOWN'
        function_payload['vmx_data'].update({'vmx3_queue_name':vmx3_queue_name})        

    # 4. Invoke presigner Lambda to generate presigned URL for recording
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
        function_payload['vmx_data'].update({'vmx3_presigned_url':presigned_url})
        logger.debug('********** Presigner Completed **********')
        logger.info('********** Voicemail Packager Step 4 of 6 Presigner Generation Complete **********')

    except Exception as e:
        logger.error('********** Failed to generate presigned URL **********')
        logger.info('********** Voicemail Packager Step 4 of 6 failed, but continuing with deliver since we have a transcript **********')
        logger.error(e)
        presigned_url = 'https://github.com/amazon-connect/voicemail-express-amazon-connect' 

    # 5. Deliver Voicemail
    # Deliver Task
    try:
        
        # 1. Set parameters
        # Make sure transcript fits in a task field and truncate if it does not.
        # Make sure transcript fits in field and truncate if it does not.
        vmx3_transcript = function_payload['function_data']['vmx3_transcript_contents']
        if len(vmx3_transcript) > 2048:
            vmx3_short_transcript = vmx3_transcript[:2048] + ' ...(truncated)'
            logger.debug('********** Transcript truncated **********')
        else:
            logger.debug('********** Transcript within limits **********')
            vmx3_short_transcript = vmx3_transcript
        #
        contact_flow = os.environ['default_task_flow']
        #    
        logger.debug('********** GenAI Summary Disabled **********')
        task_references = {
            'Date Received': {
                'Value': function_payload['vmx_data']['vmx3_datetime'],
                'Type': 'STRING'
            },
            'Source Queue': {
                'Value': function_payload['vmx_data']['vmx3_queue_name'],
                'Type':'STRING'
            },
            'Voicemail Transcript': {
                'Value': vmx3_short_transcript,
                'Type':'STRING'
            },
            'GenAI Summary': {
                'Value': 'Not enabled for this voicemail.',
                'Type':'STRING'
            },
            'Playback URL': {
                'Value': function_payload['vmx_data']['vmx3_presigned_url'],
                'Type': 'URL',
            }
        }
        task_description = vmx3_short_transcript
        logger.info('********** Sub: Voicemail to Task Step 1 of 2 Complete **********')

        # 2. Create the task and return response if successful
        create_task = connect_client.start_task_contact(
            InstanceId=function_payload['function_data']['instance_id'],
            ContactFlowId=contact_flow,
            PreviousContactId=function_payload['function_data']['contact_id'],
            Attributes={
                'vmx3_callback_number': function_payload['vmx_data']['vmx3_from'],
                'vmx3_timestamp': function_payload['vmx_data']['vmx3_datetime'],
                'vmx3_source_queue': function_payload['vmx_data']['vmx3_queue_name'],
                'vmx3_transcript': vmx3_short_transcript
            },
            Name='Amazon Connect Voicemail',
            References=task_references,
            Description=task_description,
            ClientToken=function_payload['function_data']['contact_id']
        )
        logger.debug(create_task)
        logger.debug('********** Voicemail Task Created **********')
        logger.info('********** Sub: Voicemail to Task Step 2 of 2 Complete **********')
        function_response.update({'result':'success','task': create_task})
        logger.info('********** Voicemail Packager Step 5 of 6 Deliver Task Complete **********')

    except Exception as e:
        logger.error('********** Failed to deliver task function **********')
        logger.info('********** Voicemail Packager Step 5 of 6 Deliver Task failed **********')
        logger.error(e)
        raise Exception      

    # 6. Do cleanup
    # Delete transcription job
    try:
        transcribe_client.delete_transcription_job(
            TranscriptionJobName='vmx3_' + contact_id
        )
        logger.debug('********** Transcribe Job Deleted **********')

    except Exception as e:
        logger.error('********** Failed to delete transcription job **********')
        logger.error(e)

    # Clear vmx3_flag for this contact
    try:
        connect_client.update_contact_attributes(
            InitialContactId=contact_id,
            InstanceId=instance_id,
            Attributes={'vmx3_flag': '0'}
        )
        logger.debug('********** vmx3_flag cleared for contact **********')
        logger.info('********** Voicemail Packager Step 6 of 6 Cleanup complete **********')
        function_response.update({'status':'complete','result':'success'})
        return {function_response}

    except Exception as e:
        logger.error('********** Failed to clear vmx3_flag **********')
        logger.info('********** Voicemail Packager Step 6 of 6 Cleanup failed **********')
        logger.error(e)