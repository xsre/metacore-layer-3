installCRDs: false

server:
    extraArgs:
    - --insecure
    nodeSelector:
        apis: duces
    config:
        resource.customizations.ignoreDifferences.all: |
            managedFieldsManagers:
            - crossplane-aws-provider

dex:
    nodeSelector:
        apis: duces

redis:
    nodeSelector:
        apis: duces

controller:
    nodeSelector:
        apis: duces

repoServer:
    nodeSelector:
        apis: duces
    env:
      - name: ARGOCD_GIT_MODULES_ENABLED
        value: "false"

applicationSet:
    nodeSelector:
        apis: duces

notifications:
    nodeSelector:
        apis: duces
