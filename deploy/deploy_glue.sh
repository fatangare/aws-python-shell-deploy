#!/bin/bash

### USAGE ####
# ./deploy/deploy_glue.sh <glue_job> -stage <stage> -cf <cf_folder>
## Arguments
### glue_job  mandatory
###     glue job name if selective glue job should be deployed
### -stage  mandatory
###     To define stage
### stage required with -stage
###     It will be used to pass stage environment parameters.
###     It can be {developer name}, dev, qa or prod.
### cf  optional
###     if specified, glue job will deployed through CF else only files will be uploaded to s3.
### cf_folder required with -cf otherwise optional
###     if specified, it will be taken as path for cf template. e.g. cf/ingeston/lambda/a_lambda.json
###         should set cf_folder to 'ingestion/lambda'

# Specify bucket in which you wish to upload zip and .py files
build_bucket='<specify build artifacts bucket>'
# Project prefix. 
project="bp"
# Default Stage
stage="dev"
# AWS profile to be used in AWS CLI
aws_profile="default"
# ARN of Glue Role to be used in Glue operation.
glue_role_arn='<specify Glue Role ARN>'

glue_job=""
if [ "$1" == "" ] 
then
  echo 'Provide glue job name or "all" as first argument'
else
  glue_job=$1_glue.py
fi

if [ "$2" == "-stage" ] 
then 
  if [ "$3" == "" ]
  then
    echo "stage must be specified with -stage parameter"
    exit 1
  else
    stage=$3
  fi
else
  echo "-stage parameter is mandatory. It can be {developer name}, dev, qa or prod."
  exit 1
fi

sync_only=true
if [ "$4" == "-cf" ] 
then
  sync_only=false
  if [ "$5" == "" ]
  then
    echo "cf-folder must be specified with -stage parameter"
    exit 1
  else
    cf_folder=$5
  fi
fi

if [ ! -d "dist" ]
then
  echo "creating dist directory"
  mkdir -p dist
fi


printf '\nzipping dependency files for each glue job and then moving to dist ...\n'
for f in */etl/src/$glue_job; do 
  dest=$(dirname "${f}")
  mkdir -p dist/$dest
  cp $f dist/$dest/.
  
  glue=${f#*/etl/src/}; 
  path=${f%$glue};

  if [ -f ${f%_glue.py}_requirements.txt ]
  then 
    printf "\ninstalling external python libraries ...\n"
    python -m pip install --no-deps -r ${f%_glue.py}_requirements.txt -t ./lib; 
    python -m pip install --upgrade --no-deps -r ${f%_glue.py}_requirements.txt -t ./lib; 
    cd lib
    printf "\nzipping external python libraries to ${glue%.py}_lib.zip file and then moving to dist ...\n"
    ls| zip -r "${glue%.py}_lib.zip" -@; mv ${glue%.py}_lib.zip ../dist/$dest/.
    cd ..
    rm -rf lib
  fi

  if [ -f ${f%_glue.py}_dependency.txt ]
  then 
    printf "\nzipping extra python files to ${glue%.py}.zip file and then moving to dist ...\n"
    dd=${f%_glue.py}_dependency.txt; 
    cat $dd | zip -r "${glue%.py}.zip" -@; mv ${glue%.py}.zip dist/$dest/.
  fi
done 
printf "\nSyncing repo with S3 code bucket\n"
aws s3 sync dist s3://$build_bucket/$stage/dist --delete --profile $aws_profile

if [ "$sync_only" = false ]
then
  for f in */etl/src/$glue_job; do 
    glueJobName=${f#*/etl/src/}; 
    glueJobName=${glueJobName%_glue.py}
    cf="cf/${cf_folder}/${glueJobName}_job.json"
    printf "\ndepolying $glueJobName job using $cf CF template ...\n"
    stackname="${glueJobName//_/-}-$stage" 
    aws cloudformation deploy --template-file $cf --stack-name $stackname --parameter-overrides ProjectName=$project BuildBucket=$build_bucket BuildFolder=$stage/dist Stage=$stage GlueRoleARN=$glue_role_arn --profile $aws_profile
  done
fi