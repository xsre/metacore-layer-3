cloudProvider: aws
awsRegion: ${region}

nameOverride: "aws"

replicaCount: 2

rbac:
  serviceAccount:
    create: false

nodeSelector:
    apis: duces

extraArgs:
  balance-similar-node-groups: true
  skip-nodes-with-local-storage: false