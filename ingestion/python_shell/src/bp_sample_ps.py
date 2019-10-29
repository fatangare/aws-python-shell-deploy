import sys
from awsglue.utils import getResolvedOptions
import pandas as pd
from config.env import Env
import boto3
import io
import s3fs


args = getResolvedOptions(sys.argv, ['stage', 'project'])
# Job input parameters
stage = args['stage']
project = args['project']

def to_excel(csv_filepath, excel_bucket, excel_filepath):
    # Read csv file from S3
    df = pd.read_csv (csv_filepath)  

    # Write to IO stream
    output = io.BytesIO()
    writer = pd.ExcelWriter(output, engine='xlsxwriter')
    df.to_excel(writer)
    writer.save()

    # Get binary data from IO stream
    data = output.getvalue()

    # Save in S3
    s3 = boto3.client('s3')
    s3.put_object(Body=data, Bucket=excel_bucket, Key=excel_filepath)
   

env = Env.get_config(project,stage)
incoming_path = "s3://{}/{}/food/food.csv".format(env["s3_data_lake"], env["incoming_folder"])
excel_path = '{}/food/food.xlsx'.format(env["primary_folder"])
to_excel(incoming_path, env["s3_data_lake"], excel_path)