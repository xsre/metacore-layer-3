replicas: 2
nodeSelector:
    apis: duces
deploymentStrategy: RollingUpdate

rbacManager:
    nodeSelector:
        apis: duces
