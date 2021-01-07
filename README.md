# AWS for Fluent Bit with Coralogix Plugin
Builds Coralogix plugin and packages it in the aws-for-fluent-bit image.

## Sample Config for Publishing to S3 and Coralogix

The sample config uses environment variables and secrets (either through parameter store secure string or secrets manager) to expose dynamic configuration items.

**Note on Reliability** - This sample configuration is for demonstration purposes only. Please consider resilence of the buffered chunks or consider a streaming middleware like Kinesis or Kafka. [S3 Plugin Reliability](https://docs.fluentbit.io/manual/pipeline/outputs/s3#reliability)

### extra.conf
```
[OUTPUT]
    Name   coralogix
    Match  *
    Private_Key ${CORALOGIX_PRIVATE_KEY}
    App_Name    ${CORALOGIX_APP_NAME}
    Sub_Name    ${CORALOGIX_SUBSYSTEM_NAME}

[OUTPUT]
    Name                s3
    Match               *
    region              ${S3_REGION}
    bucket              ${S3_BUCKET}
    total_file_size     10M
    upload_timeout      1m
```

### taskdef.json
```json
{
    "family": "simple-logging-app-task-def",
    "taskRoleArn": "arn:aws:iam::<account id>:role/simple-logging-app-role",
    "executionRoleArn": "arn:aws:iam::<account id>:role/ecsTaskExecutionRole",
    "networkMode": "bridge",
    "requiresCompatibilities": [
        "EC2"
    ],
    "containerDefinitions": [
        {
            "essential": true,
            "image": "<account id>.dkr.ecr.<region>.amazonaws.com/coralogixrepo/aws-for-fluent-bit-coralogix:2.10.0",
            "name": "firelens-container",
            "firelensConfiguration": {
                "type": "fluentbit",
                "options": {
                    "config-file-type": "s3",
                    "config-file-value": "arn:aws:s3:::<bucket>/extra.conf"
                }
            },
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "firelens-container",
                    "awslogs-region": "<region>",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "simple-logging-app"
                }
            },
            "memoryReservation": 50,
            "environment": [
                
                {
                    "name": "CORALOGIX_APP_NAME",
                    "value": "simple-logging-app"
                },
                {
                    "name": "CORALOGIX_SUBSYSTEM_NAME",
                    "value": "shell-script"
                },
                {
                    "name": "S3_BUCKET",
                    "value": "<logs bucket>"
                },
                {
                    "name": "S3_REGION",
                    "value": "<region>"
                }
            ],
            "secrets": [
                {
                    "name": "CORALOGIX_PRIVATE_KEY",
                    "valueFrom": "/coralogix/private-key"
                }
            ]
         },
         {
            "essential": true,
            "image": "<account id>.dkr.ecr.<region>.amazonaws.com/simple-logging-app:0.2.0",
            "name": "simple-logging-app",
            "dependsOn": [
                {
                    "containerName": "firelens-container",
                    "condition": "START"
                }
            ],
            "logConfiguration": {
                "logDriver":"awsfirelens"
            },
            "memoryReservation": 100
        }
    ]
}
```

## References
 * [AWS for Fluent Bit](https://github.com/aws/aws-for-fluent-bit)

 * [Coralogix Fluent Bit Plugin](https://coralogix.com/integrations/fluent-bit/)
