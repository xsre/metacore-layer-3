installCRDs: true

nodeSelector:
    apis: duces

cainjector:
    nodeSelector:
        apis: duces

webhook:
    nodeSelector:
        apis: duces