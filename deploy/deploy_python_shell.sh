#!/bin/bash

### USAGE ####
# ./deploy/deploy_glue.sh <glue_job> -stage <stage> -sync
## Arguments
### glue_job  mandatory
###     glue job name if selective python shell job should be deployed
### -stage  mandatory
###     To define stage
### stage required with -stage
###     It will be used to pass stage environment parameters.
###     It can be {developer name}, dev, qa or prod.
### sync  optional
###     if specified, only files will be uploaded to s3 and CF will not be deployed/updated.

# # Specify bucket in which you wish to upload zip and .py files
# build_bucket='<specify build artifacts bucket>'
# # Project prefix. 
# project="bp"
# # Default Stage
# stage="dev"
# # AWS profile to be used in AWS CLI
# aws_profile="default"
# # ARN of Glue Role to be used in Glue operation.
# glue_role_arn='<specify Glue Role ARN>'

# Specify bucket in which you wish to upload zip and .py files
build_bucket='sandeep-rnd'
# Project prefix. 
project="bp"
# Default Stage
stage="dev"
# AWS profile to be used in AWS CLI
aws_profile="default"
# ARN of Glue Role to be used in Glue operation.
glue_role_arn='arn:aws:iam::160699259667:role/AVA_GLUE_ROLE'


# Egg package version
egg_package_version=0.1
# Python version used to make egg file
python_version=`python -c "import sys;t='{v[0]}.{v[1]}'.format(v=list(sys.version_info[:2]));sys.stdout.write(t)";`

python_shell=""
if [ "$1" == "" ] 
then
  echo 'Provide glue job name or "all" as first argument'
else
  python_shell=$1_ps.py
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

sync_only=false
if [ "$4" == "-sync" ] 
then
  sync_only=true
fi

if [ ! -d "dist" ]
then
  echo "creating dist directory ..."
  mkdir -p dist
fi

path=`pwd`

printf "\ncreating .egg file and then moving to dist ...\n"
for f in */python_shell/src/$python_shell; do
  echo 'copying python_shell files to dist'
  dest=$(dirname "${f}")
  echo ${f%src*}
  mkdir -p dist/$dest
  cp $f dist/$dest/.

  python_shell_name=${f#*/src/}
  python_shell_name=${python_shell_name%_ps.py}
  cd $dest
  if [ -f ${python_shell_name}_setup.py ]
  then
    printf "\Creating egg file containing extra python files and external libraries to ${python_shell_name%.py}.zip file and then moving to dist ...\n"
    python ${python_shell_name}_setup.py bdist_egg -d $path/dist/$dest
    rm -rf build
    rm -rf *.egg-info
  fi
  cd $path

  printf "\nSyncing repo with S3 code bucket ...\n"
  # aws s3 sync dist s3://$build_bucket/$stage/dist --delete --profile $aws_profile

  if [ "$sync_only" = false ]
  then
    cf_folder=${f%/src*}
    cf="cf/${cf_folder}/${python_shell_name}_job.json"
    printf "\ndeploying $python_shell_name job using $cf CF template ...\n"
    stackname="${python_shell_name//_/-}-$stage"
    aws cloudformation deploy --template-file $cf --stack-name $stackname --parameter-overrides ProjectName=$project BuildBucket=$build_bucket BuildFolder=$stage/dist\
     Stage=$stage GlueRoleARN=$glue_role_arn EggPackageVersion=$egg_package_version PythonVersion=$python_version \
     GlueJobScriptRelativePath=${cf_folder}/src \
      --profile $aws_profile 
  fi
done