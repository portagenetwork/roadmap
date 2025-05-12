# dmp-roadmap

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.3.0](https://img.shields.io/badge/AppVersion-4.3.0-informational?style=flat-square)

Helm chart for DMP Roadmap - A Data Management Planning tool that helps researchers and organizations create, share, and update data management plans

**Homepage:** <https://dmp-pgd.ca/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| University of Alberta Library | <library.dmptool@ualberta.ca> | <https://library.ualberta.ca/> |
| University of Victoria Research Computing Services | <arcsupport@uvic.ca> | <https://www.uvic.ca/systems/researchcomputing/index.php> |

## Source Code

* <https://github.com/portagenetwork/roadmap>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| app.affinity | object | `{}` | Affinity settings for the app deployment |
| app.autoscaling | object | `{"enabled":false,"maxReplicas":100,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Autoscaling configuration for the app |
| app.autoscaling.enabled | bool | `false` | Enable autoscaling for the app |
| app.autoscaling.maxReplicas | int | `100` | Maximum number of replicas |
| app.autoscaling.minReplicas | int | `1` | Minimum number of replicas |
| app.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilization percentage |
| app.env | list | `[]` | Environment variables to pass to DMP Roadmap app |
| app.envFrom | list | `[]` | envFrom to pass to DMP Roadmap app |
| app.image.imagePullPolicy | string | global.image.imagePullPolicy | Image pull policy for the DMP Roadmap app |
| app.image.repository | string | global.image.repository | Repository to use for the DMP Roadmap app |
| app.image.tag | string | global.image.tag or chart appVersion | Tag to use for the DMP Roadmap app |
| app.imagePullSecrets | list | global.imagePullSecrets | Secrets with credentials to pull images from a private registry |
| app.livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/api/v1/heartbeat","port":"http"},"initialDelaySeconds":120,"periodSeconds":20,"successThreshold":1,"timeoutSeconds":10}` | Liveness probe configuration for the app |
| app.nodeSelector | object | `{}` | Node selector for the app deployment |
| app.podAnnotations | object | `{}` | Pod annotations for the app deployment |
| app.podLabels | object | `{}` | Pod labels for the app deployment |
| app.podSecurityContext | object | `{"fsGroup":3000}` | Pod security context for the app deployment |
| app.readinessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/api/v1/heartbeat","port":"http"},"initialDelaySeconds":60,"periodSeconds":20,"successThreshold":1,"timeoutSeconds":10}` | Readiness probe configuration for the app |
| app.replicas | int | `1` | Number of app replicas |
| app.resources | object | `{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"200m","memory":"512Mi"}}` | Resource requests and limits for the app |
| app.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context for the app deployment |
| app.service.port | int | `8080` | Service port for the app |
| app.service.targetPort | int | `3000` | Target port for the app container |
| app.service.type | string | `"ClusterIP"` | Service type for the app |
| app.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| app.serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| app.serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| app.serviceAccount.name | string | If not set and create is true, a name is generated using the fullname template | The name of the service account to use. |
| app.tolerations | list | `[]` | Tolerations for the app deployment |
| app.volumeMounts | list | `[]` | Additional volume mounts for the app deployment |
| app.volumes | list | `[]` | Additional volumes for the app deployment |
| assets.affinity | object | `{}` | Affinity settings for the assets deployment |
| assets.autoscaling | object | `{"enabled":false,"maxReplicas":100,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Autoscaling configuration for the assets |
| assets.autoscaling.enabled | bool | `false` | Enable autoscaling for the assets |
| assets.autoscaling.maxReplicas | int | `100` | Maximum number of replicas |
| assets.autoscaling.minReplicas | int | `1` | Minimum number of replicas |
| assets.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilization percentage |
| assets.env | list | `[]` | Environment variables to pass to DMP Roadmap assets |
| assets.envFrom | list | `[]` | envFrom to pass to DMP Roadmap assets |
| assets.image.imagePullPolicy | string | global.image.imagePullPolicy | Image pull policy for the DMP Roadmap assets |
| assets.image.repository | string | global.image.repository | Repository to use for the DMP Roadmap assets |
| assets.image.tag | string | global.image.tag or chart appVersion | Tag to use for the DMP Roadmap assets |
| assets.imagePullSecrets | list | global.imagePullSecrets | Secrets with credentials to pull images from a private registry |
| assets.livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":120,"periodSeconds":20,"successThreshold":1,"timeoutSeconds":10}` | Liveness probe configuration for the assets |
| assets.nodeSelector | object | `{}` | Node selector for the assets deployment |
| assets.podAnnotations | object | `{}` | Pod annotations for the assets deployment |
| assets.podLabels | object | `{}` | Pod labels for the assets deployment |
| assets.podSecurityContext | object | `{"fsGroup":3000}` | Pod security context for the assets deployment |
| assets.readinessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/healthz","port":"http"},"initialDelaySeconds":60,"periodSeconds":20,"successThreshold":1,"timeoutSeconds":10}` | Readiness probe configuration for the assets |
| assets.replicas | int | `1` | Number of assets replicas |
| assets.resources | object | `{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource requests and limits for the assets |
| assets.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context for the assets deployment |
| assets.service.port | int | `8080` | Service port for the assets |
| assets.service.targetPort | int | `8080` | Target port for the assets container |
| assets.service.type | string | `"ClusterIP"` | Service type for the assets |
| assets.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| assets.serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| assets.serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| assets.serviceAccount.name | string | If not set and create is true, a name is generated using the fullname template | The name of the service account to use. |
| assets.tolerations | list | `[]` | Tolerations for the assets deployment |
| assets.volumeMounts | list | `[]` | Additional volume mounts for the assets deployment |
| assets.volumes | list | `[]` | Additional volumes for the assets deployment |
| config | object | `{"application":{"dmproadmapHost":"","httpProxy":"","httpProxyPort":"","onSandbox":"false"},"environment":{"assetHost":"","baseUrl":"","bundlePath":"vendor/bundle","bundleWithout":"development:test:mysql:aws:sandbox:ci:wkhtmltopdf","defaultFunderId":8,"englishOrgId":"","frenchOrgId":"","funderOrgId":"","locale":"en_CA.UTF-8","nodeEnv":"production","omniauthFullHost":"","orcidClientMember":"false","railsEnv":"production","railsLogToStdout":"true","railsServeStaticFiles":"false","railsSkipAssetCompilation":"true","rakeEnv":"production","rollbarEnv":"arbutus-test","tmpDir":"/usr/src/app/tmp","wickedPdfPath":"/usr/bin/wkhtmltopdf","wickedPdfProxy":""},"mailer":{"defaultHost":"","from":"support@portagenetwork.ca","smtpAddress":"smtp.gmail.com","smtpAuthentication":"plain","smtpDomain":"portagenetwork.ca","smtpPort":587,"to":"support@portagenetwork.ca"}}` | Configuration values for the application |
| config.application | object | `{"dmproadmapHost":"","httpProxy":"","httpProxyPort":"","onSandbox":"false"}` | Application and host settings |
| config.application.dmproadmapHost | string | global.domain.name | Main hostname for the application |
| config.application.httpProxy | string | `""` | HTTP proxy if needed |
| config.application.httpProxyPort | string | `""` | HTTP proxy port if needed |
| config.application.onSandbox | string | `"false"` | Set to true for sandbox mode |
| config.environment | object | `{"assetHost":"","baseUrl":"","bundlePath":"vendor/bundle","bundleWithout":"development:test:mysql:aws:sandbox:ci:wkhtmltopdf","defaultFunderId":8,"englishOrgId":"","frenchOrgId":"","funderOrgId":"","locale":"en_CA.UTF-8","nodeEnv":"production","omniauthFullHost":"","orcidClientMember":"false","railsEnv":"production","railsLogToStdout":"true","railsServeStaticFiles":"false","railsSkipAssetCompilation":"true","rakeEnv":"production","rollbarEnv":"arbutus-test","tmpDir":"/usr/src/app/tmp","wickedPdfPath":"/usr/bin/wkhtmltopdf","wickedPdfProxy":""}` | Environment-specific settings |
| config.environment.assetHost | string | https://global.domain.name | Asset host |
| config.environment.baseUrl | string | https://global.domain.name/global.domain.path | Base URL |
| config.environment.bundlePath | string | `"vendor/bundle"` | Bundle path |
| config.environment.bundleWithout | string | `"development:test:mysql:aws:sandbox:ci:wkhtmltopdf"` | Bundle without |
| config.environment.defaultFunderId | int | `8` | Default funder ID |
| config.environment.englishOrgId | string | `""` | English organization ID |
| config.environment.frenchOrgId | string | `""` | French organization ID |
| config.environment.funderOrgId | string | `""` | Funder organization ID |
| config.environment.locale | string | `"en_CA.UTF-8"` | Locale |
| config.environment.nodeEnv | string | `"production"` | Node environment |
| config.environment.omniauthFullHost | string | https://global.domain.name/global.domain.path | OAuth callback URL |
| config.environment.orcidClientMember | string | `"false"` | Whether ORCID client is a member |
| config.environment.railsEnv | string | `"production"` | Rails environment |
| config.environment.railsLogToStdout | string | `"true"` | Rails log to stdout |
| config.environment.railsServeStaticFiles | string | `"false"` | Rails serve static files |
| config.environment.railsSkipAssetCompilation | string | `"true"` | Rails skip asset compilation |
| config.environment.rakeEnv | string | `"production"` | Rake environment |
| config.environment.rollbarEnv | string | `"arbutus-test"` | Rollbar environment |
| config.environment.tmpDir | string | `"/usr/src/app/tmp"` | Tmp directory |
| config.environment.wickedPdfPath | string | `"/usr/bin/wkhtmltopdf"` | Path to wkhtmltopdf binary |
| config.environment.wickedPdfProxy | string | `""` | Proxy for wkhtmltopdf if needed |
| config.mailer | object | `{"defaultHost":"","from":"support@portagenetwork.ca","smtpAddress":"smtp.gmail.com","smtpAuthentication":"plain","smtpDomain":"portagenetwork.ca","smtpPort":587,"to":"support@portagenetwork.ca"}` | Mailer and SMTP settings |
| config.mailer.defaultHost | string | https://global.domain.name | Default host for mailer |
| config.mailer.from | string | `"support@portagenetwork.ca"` | From address for emails |
| config.mailer.smtpAddress | string | `"smtp.gmail.com"` | SMTP server address |
| config.mailer.smtpAuthentication | string | `"plain"` | SMTP authentication method |
| config.mailer.smtpDomain | string | `"portagenetwork.ca"` | SMTP domain |
| config.mailer.smtpPort | int | `587` | SMTP port |
| config.mailer.to | string | `"support@portagenetwork.ca"` | To address for system emails |
| cronjobs | object | `{"researchDataOutput":{"affinity":{},"concurrencyPolicy":"Forbid","enabled":true,"env":[],"failedJobsHistoryLimit":1,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"priorityClassName":"","resources":{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartPolicy":"OnFailure","schedule":"0 0 * * *","successfulJobsHistoryLimit":3,"suspend":false,"tolerations":[],"volumeMounts":[],"volumes":[]},"translationSync":{"affinity":{},"concurrencyPolicy":"Forbid","enabled":true,"env":[],"failedJobsHistoryLimit":1,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"priorityClassName":"","resources":{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartPolicy":"OnFailure","schedule":"*/5 * * * *","successfulJobsHistoryLimit":3,"suspend":false,"tolerations":[],"volumeMounts":[],"volumes":[]}}` | Scheduled tasks for the application |
| cronjobs.researchDataOutput | object | `{"affinity":{},"concurrencyPolicy":"Forbid","enabled":true,"env":[],"failedJobsHistoryLimit":1,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"priorityClassName":"","resources":{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartPolicy":"OnFailure","schedule":"0 0 * * *","successfulJobsHistoryLimit":3,"suspend":false,"tolerations":[],"volumeMounts":[],"volumes":[]}` | Research Data Output CronJob configuration |
| cronjobs.researchDataOutput.affinity | object | app.affinity | Affinity rules for the CronJob |
| cronjobs.researchDataOutput.concurrencyPolicy | string | `"Forbid"` | Concurrency policy for CronJob (Allow, Forbid, Replace) |
| cronjobs.researchDataOutput.enabled | bool | `true` | Enable or disable the research data output CronJob |
| cronjobs.researchDataOutput.env | list | `[]` | Additional environment variables for the CronJob |
| cronjobs.researchDataOutput.failedJobsHistoryLimit | int | `1` | Number of failed job history to keep |
| cronjobs.researchDataOutput.nodeSelector | object | app.nodeSelector | Node selector for the CronJob |
| cronjobs.researchDataOutput.podAnnotations | object | `{}` | Pod annotations for the CronJob pods |
| cronjobs.researchDataOutput.podLabels | object | `{}` | Pod labels for the CronJob pods |
| cronjobs.researchDataOutput.priorityClassName | string | app.priorityClassName or global.priorityClassName | Priority class name for the CronJob |
| cronjobs.researchDataOutput.resources | object | `{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}}` | Resource limits and requests for the CronJob |
| cronjobs.researchDataOutput.restartPolicy | string | `"OnFailure"` | Restart policy for the job pods |
| cronjobs.researchDataOutput.schedule | string | `"0 0 * * *"` | Schedule for the CronJob (cron format) |
| cronjobs.researchDataOutput.successfulJobsHistoryLimit | int | `3` | Number of successful job history to keep |
| cronjobs.researchDataOutput.suspend | bool | `false` | Whether to suspend the job execution |
| cronjobs.researchDataOutput.tolerations | list | app.tolerations | Tolerations for the CronJob |
| cronjobs.researchDataOutput.volumeMounts | list | `[]` | Additional volume mounts for the CronJob |
| cronjobs.researchDataOutput.volumes | list | `[]` | Additional volumes for the CronJob |
| cronjobs.translationSync | object | `{"affinity":{},"concurrencyPolicy":"Forbid","enabled":true,"env":[],"failedJobsHistoryLimit":1,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"priorityClassName":"","resources":{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartPolicy":"OnFailure","schedule":"*/5 * * * *","successfulJobsHistoryLimit":3,"suspend":false,"tolerations":[],"volumeMounts":[],"volumes":[]}` | Translation Sync CronJob configuration |
| cronjobs.translationSync.affinity | object | app.affinity | Affinity rules for the CronJob |
| cronjobs.translationSync.concurrencyPolicy | string | `"Forbid"` | Concurrency policy for CronJob (Allow, Forbid, Replace) |
| cronjobs.translationSync.enabled | bool | `true` | Enable or disable the translation sync CronJob |
| cronjobs.translationSync.env | list | `[]` | Additional environment variables for the CronJob |
| cronjobs.translationSync.failedJobsHistoryLimit | int | `1` | Number of failed job history to keep |
| cronjobs.translationSync.nodeSelector | object | app.nodeSelector | Node selector for the CronJob |
| cronjobs.translationSync.podAnnotations | object | `{}` | Pod annotations for the CronJob pods |
| cronjobs.translationSync.podLabels | object | `{}` | Pod labels for the CronJob pods |
| cronjobs.translationSync.priorityClassName | string | app.priorityClassName or global.priorityClassName | Priority class name for the CronJob |
| cronjobs.translationSync.resources | object | `{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}}` | Resource limits and requests for the CronJob |
| cronjobs.translationSync.restartPolicy | string | `"OnFailure"` | Restart policy for the job pods |
| cronjobs.translationSync.schedule | string | `"*/5 * * * *"` | Schedule for the CronJob (cron format) |
| cronjobs.translationSync.successfulJobsHistoryLimit | int | `3` | Number of successful job history to keep |
| cronjobs.translationSync.suspend | bool | `false` | Whether to suspend the job execution |
| cronjobs.translationSync.tolerations | list | app.tolerations | Tolerations for the CronJob |
| cronjobs.translationSync.volumeMounts | list | `[]` | Additional volume mounts for the CronJob |
| cronjobs.translationSync.volumes | list | `[]` | Additional volumes for the CronJob |
| extraObjects | list | `[]` | Extra Kubernetes objects to deploy |
| fullnameOverride | string | `""` | String to fully override `dmp-roadmap.fullname` |
| global.additionalLabels | object | `{}` | Common labels for the all resources |
| global.deploymentAnnotations | object | `{}` | Annotations for the all deployed Deployments |
| global.domain | object | `{"name":"dmp-pgd.ca","path":"","prefix":""}` | Global domain configuration |
| global.domain.name | string | `"dmp-pgd.ca"` | Main domain name used throughout the chart |
| global.domain.path | string | `""` | Application path/context (e.g., /staging) |
| global.domain.prefix | string | `""` | Application prefix (e.g., staging) |
| global.env | list | `[]` | Environment variables to pass to all deployed Deployments |
| global.image | object | `{"imagePullPolicy":"IfNotPresent","repository":"ualbertalib/dmp_roadmap","tag":""}` | Default image used by all components |
| global.image.imagePullPolicy | string | `"IfNotPresent"` | If defined, a imagePullPolicy applied to all DMP Roadmap deployments |
| global.image.repository | string | `"ualbertalib/dmp_roadmap"` | If defined, a repository applied to all DMP Roadmap deployments |
| global.image.tag | string | `""` | Overrides the global DMP Roadmap image tag whose default is the chart appVersion |
| global.imagePullSecrets | list | `[]` | Secrets with credentials to pull images from a private registry |
| global.podAnnotations | object | `{}` | Annotations for the all deployed pods |
| global.podLabels | object | `{}` | Labels for the all deployed pods |
| global.priorityClassName | string | `""` | Default priority class for all components |
| global.statefulsetAnnotations | object | `{}` | Annotations for the all deployed Statefulsets |
| ingress.annotations | object | `{}` | Annotations for the ingress resource |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable or disable the ingress |
| ingress.tls | list | `[]` | TLS configuration for the ingress |
| nameOverride | string | `""` | Provide a name in place of `dmp-roadmap` |
| namespaceOverride | string | `.Release.Namespace` | Override the namespace |
| networkPolicy | object | `{"components":[{"component":"app","name":"app","port":3000},{"component":"assets","name":"assets","port":8080},{"name":"cronjobs","partOf":"cronjob","port":3000}],"enabled":false,"ingressSource":{"namespaceSelector":{},"podSelector":{}}}` | Network policy configuration |
| networkPolicy.components | list | `[{"component":"app","name":"app","port":3000},{"component":"assets","name":"assets","port":8080},{"name":"cronjobs","partOf":"cronjob","port":3000}]` | Components to create network policies for |
| networkPolicy.components[0] | object | `{"component":"app","name":"app","port":3000}` | App component |
| networkPolicy.components[0].component | string | `"app"` | Component label |
| networkPolicy.components[0].port | int | `3000` | Target port |
| networkPolicy.components[1] | object | `{"component":"assets","name":"assets","port":8080}` | Assets component |
| networkPolicy.components[1].component | string | `"assets"` | Component label |
| networkPolicy.components[1].port | int | `8080` | Target port |
| networkPolicy.components[2] | object | `{"name":"cronjobs","partOf":"cronjob","port":3000}` | CronJobs component |
| networkPolicy.components[2].partOf | string | `"cronjob"` | Component label |
| networkPolicy.components[2].port | int | `3000` | Target port |
| networkPolicy.enabled | bool | `false` | Enable network policies |
| networkPolicy.ingressSource | object | `{"namespaceSelector":{},"podSelector":{}}` | Ingress source configuration |
| networkPolicy.ingressSource.namespaceSelector | object | `{}` | Namespace selector for ingress controller |
| networkPolicy.ingressSource.podSelector | object | `{}` | Pod selector for ingress controller |
| storage | object | `{"cephfs":{"accessModes":["ReadWriteMany"],"monitors":[],"persistentVolumeReclaimPolicy":"Retain","volumeMode":"Filesystem","volumes":{"locales":{"mountPath":"/usr/src/app/config/locale","path":"","secretRef":"cephfs-locales-key","size":"5Gi"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","path":"","secretRef":"cephfs-uploads-key","size":"5Gi"}}},"type":"cephfs"}` | Storage configuration for the application |
| storage.cephfs | object | `{"accessModes":["ReadWriteMany"],"monitors":[],"persistentVolumeReclaimPolicy":"Retain","volumeMode":"Filesystem","volumes":{"locales":{"mountPath":"/usr/src/app/config/locale","path":"","secretRef":"cephfs-locales-key","size":"5Gi"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","path":"","secretRef":"cephfs-uploads-key","size":"5Gi"}}}` | CephFS storage configuration |
| storage.cephfs.accessModes | list | `["ReadWriteMany"]` | Access modes for the volumes |
| storage.cephfs.monitors | list | `[]` | CephFS monitors |
| storage.cephfs.persistentVolumeReclaimPolicy | string | `"Retain"` | Storage reclaim policy |
| storage.cephfs.volumeMode | string | `"Filesystem"` | Volume mode |
| storage.cephfs.volumes | object | `{"locales":{"mountPath":"/usr/src/app/config/locale","path":"","secretRef":"cephfs-locales-key","size":"5Gi"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","path":"","secretRef":"cephfs-uploads-key","size":"5Gi"}}` | Volume definitions for CephFS |
| storage.cephfs.volumes.locales | object | `{"mountPath":"/usr/src/app/config/locale","path":"","secretRef":"cephfs-locales-key","size":"5Gi"}` | Locales volume configuration |
| storage.cephfs.volumes.locales.mountPath | string | `"/usr/src/app/config/locale"` | Mount path for the locales volume |
| storage.cephfs.volumes.locales.path | string | `""` | Path for the locales volume |
| storage.cephfs.volumes.locales.secretRef | string | `"cephfs-locales-key"` | Secret reference for the locales volume |
| storage.cephfs.volumes.locales.size | string | `"5Gi"` | Size for the locales volume |
| storage.cephfs.volumes.uploads | object | `{"mountPath":"/usr/src/app/public/system/dragonfly","path":"","secretRef":"cephfs-uploads-key","size":"5Gi"}` | Uploads volume configuration |
| storage.cephfs.volumes.uploads.mountPath | string | `"/usr/src/app/public/system/dragonfly"` | Mount path for the uploads volume |
| storage.cephfs.volumes.uploads.path | string | `""` | Path for the uploads volume |
| storage.cephfs.volumes.uploads.secretRef | string | `"cephfs-uploads-key"` | Secret reference for the uploads volume |
| storage.cephfs.volumes.uploads.size | string | `"5Gi"` | Size for the uploads volume |
| storage.type | string | `"cephfs"` | Storage type (cephfs) |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
