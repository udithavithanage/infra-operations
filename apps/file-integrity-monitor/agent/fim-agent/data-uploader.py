#  Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
# 
#  WSO2 LLC. licenses this file to you under the Apache License,
#  Version 2.0 (the "License"); you may not use this file except
#  in compliance with the License.
#  You may obtain a copy of the License at
# 
#  http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License. 

import os
import time
import boto3
import configparser
import logging
from dotenv import load_dotenv

# Load environment variables from .env (if present)
load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)

logger = logging.getLogger('fim-s3-uploader')

CONFIG_FILE = 'fim-agent.conf'

config = configparser.ConfigParser()
config.read(CONFIG_FILE)

# General limits
FILE_SIZE_LIMIT = int(
    config['DEFAULT'].get('FILE_SIZE_MB', 10)
) * 1024 * 1024  # MB → bytes

# S3 settings
def _require_non_empty(section, key):
    value = config[section].get(key, "").strip()
    if not value:
        raise ValueError(f"Missing required config: [{section}] {key}")
    return value
    
BUCKET_NAME = _require_non_empty("S3", "BUCKET_NAME")
JSON_DIR = _require_non_empty("S3", "JSON_DIR")

UPLOAD_INTERVAL = int(config['S3'].get('UPLOAD_INTERVAL', 300))

AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID", "").strip()
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY", "").strip()
AWS_REGION = config['S3'].get('AWS_REGION', 'us-west-2')


def initialize_s3_client():
    client_kwargs = {"region_name": AWS_REGION}
    if AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY:
        client_kwargs["aws_access_key_id"] = AWS_ACCESS_KEY_ID
        client_kwargs["aws_secret_access_key"] = AWS_SECRET_ACCESS_KEY
    return boto3.client("s3", **client_kwargs)

def upload_to_s3(s3_client, bucket_name, file_path):
    try:
        s3_client.upload_file(
            file_path,
            bucket_name,
            os.path.basename(file_path)
        )

        if os.path.exists(file_path):
            os.remove(file_path)

    except Exception as e:
        logger.error("Failed to upload %s: %s", file_path, e)


def upload_files_periodically(s3_client, bucket_name, json_dir, interval):

    logger.info(
        "FIM S3 uploader started | bucket=%s | interval=%ds | max_file=%d bytes",
        bucket_name,
        interval,
        FILE_SIZE_LIMIT
    )

    while True:
        try:
            files = [
                os.path.join(json_dir, f)
                for f in os.listdir(json_dir)
                if f.endswith('.json')
                and os.path.isfile(os.path.join(json_dir, f))
            ]

            for file_path in files:
                try:
                    file_size = os.path.getsize(file_path)

                    if file_size > FILE_SIZE_LIMIT:
                        logger.warning(
                            "Skipped oversized file: %s (%d bytes)",
                            file_path,
                            file_size
                        )
                        continue

                    upload_to_s3(s3_client, bucket_name, file_path)

                except FileNotFoundError:
                    continue

            time.sleep(interval)

        except Exception:
            logger.exception("Upload loop error")
            time.sleep(5)

if __name__ == "__main__":
    s3_client = initialize_s3_client()
    upload_files_periodically(
        s3_client,
        BUCKET_NAME,
        JSON_DIR,
        UPLOAD_INTERVAL
    )
