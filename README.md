# aws-python-shell-deploy-utility
Boilerplate for deploying python shell jobs through shell script. 

For developers, it will be useful as script can :
* Create egg file packaging extra py files and external libraries
* Upload main .py and .egg files to s3 bucket
* Deploy python shell job through cloudformation

It also allows deployment for different stages e.g. {developer}, dev, qa, prod.

Currently script allows to deploy one python shell job at a time. With tweak, it can also be used in Jenkins CI/CD to deploy all python shell jobs.

## Requirements
* Any shell tool e.g. Cygwin or Gitbash
* aws cli
* S3 bucket to store .egg and .py files

## How-to Use Script

### Folder Structure 
1. Python shell job files must be kept under *<module>/python_shell/src* folder.
2. Filename must always have prefix <project name> e.g. **bp**_sample_ps.py for **bp** project
3. Entry file of python shell job must have naming convnetion as *<project name>_<job name>_ps.py* e.g. bp_sample_ps.py for **bp** project, **sample** python shell job.
4. Egg package setup file must have naming convnetion as *<project name>_<job name>_setup.py* e.g. bp_sample_ps.py for **bp** project, **sample** python.
5. Cloudformation template files for python shell job must be kept under *cf/<module>/python_shell* folder.
6. Cludformation template must have naming convnetion as *<project name>_<job name>_job.pjson* e.g. bp_sample_job.json for **bp** project, **sample** python shell job.

### ENV Configuration
Add ENV configuration in **utility/src/config/env.py** file for different stages

**Example of ENV Configuration**:

```python
'aws_region':'us_east_1',
's3_data_lake':'{}-data-lake-{}'.format(project, STAGE),
'incoming_folder':'incoming',
'primary_folder': 'primary',
'glue_role':'{}_glue_role_{}'.format(project, STAGE)
```

### Deploy Script Configuration
Modify following configuration in deploy/deploy_python_shell.sh

```python
# Specify bucket in which you wish to upload zip and .py files
build_bucket='<specify build artifacts bucket>'
# Project prefix. 
project="<project prefix>"
# Default Stage
stage="dev"
# AWS profile to be used in AWS CLI
aws_profile="default"
# ARN of Glue Role to be used in Glue operation.
glue_role_arn='<specify Glue Role ARN>'
# Egg package version
egg_package_version=<Egg Package version. Default: 0.1>
```

### Run Deploy Script

```shell
## Usage

### To Deploy: ./deploy/deploy_python_shell.sh <python_shell_job> -stage <stage>
### To Sync S3: ./deploy/deploy_python_shell.sh <python_shell_job> -stage <stage> -sync

## Arguments

### python_shell_job    mandatory
###                     python shell job name if selective python shell job should be deployed. It should be _ps.py file name without _ps.py 
###                     e.g. for bp_sample_ps.python_shell_job will be *bp_sample*.

### -stage              mandatory
###                     To define stage

### stage               mandatory with -stage
###                     it will be used to pass stage environment parameters.
###                     it can be {developer name}, dev, qa or prod.
###                     {developer name} is useful in case of multiple developers are working on same job in same region.

### -sync               optional
###                     if specified, only files will be synced to s3 and CF will not be deployed/updated.
###                     it is useful during development where modifications are frequent in source code than in cloudformation template.
```

> Always run script from project root folder instead of from *deploy* folder.

> If Python shell job is already deployed through Cloudformation and you wish to only sync Python shell  source code with S3 bucket, omit -cf. It will sync S3 but will not attempt to update CF.

### Example

```shell
./deploy/deploy_python_shell.sh bp_sample -stage sandeep
```

1. It will deploy **bp_sample_ps.py** python shell job along with its depedencies using **sandeep** stage environment and **bp_sample_job.json** kept at **cf/ingestion/python_shell** location. 
2. In S3, files will be stored at **<build_bucket>/sandeep** location.
3. In Cloudformation, **bp-sample-sandeep** stack will be deployed
4. Python shel job **bp-sample-sandeep** will be created.

**Bonus**: You may also use clean.sh to clean temp files created during build. It may be useful during pushing code to git or distributing/sharing to others.
