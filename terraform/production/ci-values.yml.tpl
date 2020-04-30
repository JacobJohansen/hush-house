image: concourse/concourse-rc
imageTag: 6.0.0-rc.41

web:
  annotations:
    rollingUpdate: "3"
  replicas: 2
  env:
    - name: CONCOURSE_X_FRAME_OPTIONS
      value: ""
  nodeSelector:
    cloud.google.com/gke-nodepool: generic-1

  resources:
    requests:
      cpu: 1500m
      memory: 1Gi
    limits:
      cpu: 1500m
      memory: 1Gi

  service:
    type: LoadBalancer
    loadBalancerIP: ${lb_address}

persistence:
  worker:
    storageClass: ssd
    size: 750Gi

worker:
  replicas: 2
  annotations:
    manual-update-revision: "1"
  terminationGracePeriodSeconds: 3600
  livenessProbe:
    periodSeconds: 60
    failureThreshold: 10
    timeoutSeconds: 45
  hardAntiAffinity: true
  env:
  - name: CONCOURSE_GARDEN_NETWORK_POOL
    value: "10.254.0.0/16"
  - name: CONCOURSE_GARDEN_MAX_CONTAINERS
    value: "500"
  - name: CONCOURSE_GARDEN_DENY_NETWORK
    value: "169.254.169.254/32"
  resources:
    limits:   { cpu: 7500m, memory: 14Gi }
    requests: { cpu: 0m,    memory: 0Gi  }

concourse:
  web:
    auth:
      mainTeam:
        localUser: admin
        github:
          team: concourse:Pivotal
      github:
        enabled: true
    externalUrl: ${external_url}
    bindPort: 80
    clusterName: ci
    containerPlacementStrategy: limit-active-tasks
    maxActiveTasksPerWorker: 5
    enableGlobalResources: true
    # encryption: { enabled: true }
    kubernetes:
      keepNamespaces: false
      enabled: false
      createTeamNamespaces: false

  worker:
    rebalanceInterval: 2h
    baggageclaim: { driver: overlay }
    healthcheckTimeout: 40s