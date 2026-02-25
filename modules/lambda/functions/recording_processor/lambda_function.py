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
import base64
import io
import urllib.parse
from datetime import datetime
from pydub import AudioSegment

logger = logging.getLogger()

def lambda_handler(event, context):
    logger.debug('Code Version: ' + current_version)
    logger.debug('VMX3 Package Version: ' + os.environ['package_version'])
    logger.debug(event)

    for record in event['Records']:
        logger.debug(record)
        voicemail_data = process_recording_data(record)
        logger.info('********** Step 1 Complete: Record Data Processed **********')
        logger.debug(voicemail_data)
    
    voicemail_audio = audio_processor(voicemail_data)
    logger.info('********** Step 2 Complete: Record Audio Processed **********')
    
    logger.info('********** Process Complete: Voicemail Message extracted and saved **********')
    return 'Voicemail Audio Processing Complete - Move to Transcriber'

def process_recording_data(record):
    record_data = json.loads(base64.b64decode(record['kinesis']['data']))
    logger.debug('********** Record data loaded **********')
    logger.debug(record_data)

    if record_data['Recordings'] is None:
        logger.debug('******** No recordings data found **********')
        return {'status':'complete','result':'ERROR','reason':'No record data'}
    
    for record in record_data['Recordings']:
        if record['ParticipantType'] == 'IVR':
            logger.info('VM Found')
            found_vm = record
            break
    else:
        logger.info('VM not found in record')

    contact_id = record_data['ContactId']
    vm_attributes = record_data['Attributes']
    vm_timestamp = vm_attributes['vmx3_timestamp']
    source_bucket = found_vm['Location'].split("/",1)[0]
    source_key = found_vm['Location'].split('/',1)[1]
    source_timestamp = found_vm['StartTimestamp']

    dt_timestamp = datetime.strptime(vm_timestamp, '%Y-%m-%dT%H:%M:%SZ')
    dt_year = dt_timestamp.strftime('%Y')
    dt_month = dt_timestamp.strftime('%m')
    dt_day = dt_timestamp.strftime('%d')

    ts1 = datetime.fromisoformat(vm_timestamp.replace('Z', '+00:00'))
    ts2 = datetime.fromisoformat(source_timestamp.replace('Z', '+00:00'))
    vm_timestamp_difference = ts1 - ts2
    vm_offset = vm_timestamp_difference.total_seconds()

    vm_key = dt_year + '/' + dt_month + '/' + dt_day + '/' + contact_id + '.wav'

    dproc_response = {
        'contact_id' : contact_id,
        'vm_attributes' : vm_attributes,
        'source_bucket' : source_bucket,
        'source_key' : source_key,
        'source_timestamp' : source_timestamp,
        'vm_timestamp' : vm_timestamp,
        'vm_bucket' : os.environ['vmx3_recordings_bucket'],
        'vm_key' : vm_key,
        'vm_offset' : vm_offset * 1000
    }
    logger.debug(dproc_response)
    return dproc_response
    
def audio_processor(recording_data):
    s3_client = boto3.client('s3')

    in_memory_audio = io.BytesIO()
    recording_obj = s3_client.download_fileobj(recording_data['source_bucket'], recording_data['source_key'],in_memory_audio)
    in_memory_audio.seek(0)
    logger.debug('********** Loaded audio to buffer **********')
    
    audio_segment = AudioSegment.from_file(in_memory_audio, format="wav")
    vm_audio = audio_segment[recording_data['vm_offset']:]
    out_buffer = io.BytesIO()
    vm_audio.export(out_buffer, format='wav')
    out_buffer.seek(0)
    logger.debug('********** Trimmed recording **********')
    
    vm_tags = {
        'vmx3_lang_value' : recording_data['vm_attributes']['vmx3_lang'],
        'vmx3_queue_arn' : recording_data['vm_attributes']['vmx3_queue_arn'],
        'vmx3_lang' : recording_data['vm_attributes']['vmx3_lang']
    }
    logger.debug(vm_tags)

    vm_encoded_tags = urllib.parse.urlencode(vm_tags)
    logger.debug(vm_encoded_tags)

    vm_upload = s3_client.upload_fileobj(out_buffer, recording_data['vm_bucket'], recording_data['vm_key'],ExtraArgs={'ContentType':'audio/wav','Tagging': vm_encoded_tags})
    return vm_upload
