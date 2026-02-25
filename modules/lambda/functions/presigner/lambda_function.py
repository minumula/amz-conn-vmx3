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
import logging
import os

logger = logging.getLogger()

def lambda_handler(event, context):
    logger.debug('Code Version: ' + current_version)
    logger.debug('VMX3 Package Version: ' + os.environ['package_version'])
    logger.debug(event)

    response = {'result': 'success'}

    try:
        use_region = os.environ['aws_region']
        s3_client = boto3.client('s3', region_name=use_region)
        logger.debug('********** S3 client initialized **********')
    except Exception as e:
        logger.error('********** S3 client failed to initialize **********')
        logger.error(e)
        raise

    try:
        expires_in = int(os.environ['url_expire_days']) * 86400

        presigned_url = s3_client.generate_presigned_url(
            'get_object',
            Params={
                'Bucket': event['recording_bucket'],
                'Key': event['recording_key']
            },
            ExpiresIn=expires_in
        )

        logger.debug('********** Presigned URL Generated successfully **********')
        logger.debug('Presigned URL: ' + presigned_url)
        response['presigned_url'] = presigned_url

        return response
    except Exception as e:
        logger.error('********** Presigned URL Failed to generate **********')
        logger.error(e)
        raise
