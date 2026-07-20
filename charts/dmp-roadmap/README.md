# DMP Roadmap Helm Chart

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.3.0](https://img.shields.io/badge/AppVersion-4.3.0-informational?style=flat-square)

A comprehensive Helm chart for deploying DMP Roadmap - A Data Management Planning tool that helps researchers and organizations create, share, and update data management plans.

## Features

- **Production-ready** deployment with security best practices
- **Flexible storage** support (PVC, CephFS, hostPath, NFS, emptyDir)
- **Database options** (embedded PostgreSQL or external database)
- **TLS & cert-manager** integration for automatic SSL certificates
- **Horizontal Pod Autoscaling** for dynamic scaling
- **Monitoring ready** with configmap change detection
- **Automated tasks** via configurable CronJobs
- **Multi-environment** support with overlay configurations

## Quick Start

### Prerequisites

- Kubernetes 1.19+
- Helm 3.8+
- PV provisioner support in the underlying infrastructure (for persistent storage)

### Installation

1. **Add the Helm repository**:
   ```bash
   helm repo add dmp-roadmap https://your-helm-repo.com
   helm repo update
   ```

2. **Install with default configuration**:
   ```bash
   helm install my-dmp-roadmap dmp-roadmap/dmp-roadmap
   ```

3. **Install with custom values**:
   ```bash
   helm install my-dmp-roadmap dmp-roadmap/dmp-roadmap \
     --set global.domain.name=dmp.example.com \
     --set postgresql.enabled=true
   ```

### Basic Configuration

Create a `values.yaml` file with your specific configuration:

```yaml
# Basic configuration
global:
  domain:
    name: dmp.example.com

# Enable ingress with TLS
ingress:
  enabled: true
  className: nginx
  certManager:
    enabled: true
    clusterIssuer: letsencrypt-prod

# Configure SMTP for emails
config:
  mailer:
    from: noreply@example.com
    to: admin@example.com
    smtpAddress: smtp.example.com
    smtpDomain: example.com
```

Then install:
```bash
helm install my-dmp-roadmap dmp-roadmap/dmp-roadmap -f values.yaml
```

## Storage Configuration

The chart supports multiple storage backends:

### Standard PVC (Default)
```yaml
storage:
  type: pvc
  pvc:
    storageClassName: "fast-ssd"
    volumes:
      locales:
        size: 5Gi
        accessModes: [ReadWriteMany]
      uploads:
        size: 10Gi
```

### CephFS
```yaml
storage:
  type: cephfs
  cephfs:
    monitors:
      - 10.0.0.1:6789
      - 10.0.0.2:6789
    volumes:
      locales:
        path: /volumes/dmp-locales
        secretRef: cephfs-secret
```

### NFS
```yaml
storage:
  type: nfs
  nfs:
    server: nfs.example.com
    volumes:
      locales:
        path: /exports/dmp-locales
      uploads:
        path: /exports/dmp-uploads
```

## Database Configuration

### Embedded PostgreSQL (Recommended for development)
TBD

### External Database (Recommended for production)
```yaml
postgresql:
  enabled: false

externalDatabase:
  host: postgres.example.com
  port: 5432
  database: dmp_roadmap_production
  username: dmp_roadmap
  existingSecret: dmp-db-secret
  existingSecretPasswordKey: password
```

## TLS & Ingress Configuration

### Automatic TLS with cert-manager
```yaml
ingress:
  enabled: true
  className: nginx
  certManager:
    enabled: true
    clusterIssuer: letsencrypt-prod
  # hosts automatically derived from global.domain.name
```

### Manual TLS Configuration
```yaml
ingress:
  enabled: true
  hosts:
    - host: dmp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: dmp-tls
      hosts:
        - dmp.example.com
```

## Production Deployment

For production deployments, consider these configurations:

```yaml
# Resource limits
app:
  replicas: 2
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 4Gi

# Autoscaling
app:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

# Persistent storage
storage:
  type: pvc
  pvc:
    storageClassName: "fast-ssd"
    volumes:
      uploads:
        size: 100Gi

# External database
postgresql:
  enabled: false
externalDatabase:
  host: postgres-cluster.internal
  existingSecret: dmp-db-credentials
```

## CronJobs

The chart includes several automated tasks:

- **Translation Sync**: Synchronizes translation files (daily at 1:00 AM)
- **Research Data Output**: Updates external research data (daily at 1:00 AM)
- **Stat Build**: Builds application statistics (daily at 1:01 AM)

Configure schedules and resources:
```yaml
cronjobs:
  translationSync:
    enabled: true
    schedule: "0 2 * * *"  # 2 AM daily
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
```

## Monitoring & Observability

The chart includes:
- **Configmap change detection**: Automatic pod rollouts when configuration changes
- **Health checks**: Liveness and readiness probes
- **Resource monitoring**: Resource requests and limits
- **Pod disruption budgets**: (configure with `podDisruptionBudget`)

## Upgrading

### From 0.x to 1.x (when available)
```bash
# Review breaking changes in CHANGELOG.md first
helm upgrade my-dmp-roadmap dmp-roadmap/dmp-roadmap --version 1.0.0
```

### Database Migrations
Database migrations are handled automatically by the application's entrypoint script. No manual intervention required.

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -l app.kubernetes.io/name=dmp-roadmap
kubectl describe pod <pod-name>
```

### Check Configuration
```bash
kubectl get configmap <release-name>-dmp-roadmap-app-config -o yaml
```

### Check Logs
```bash
kubectl logs -l app.kubernetes.io/name=dmp-roadmap -c dmp-roadmap
```

### Storage Issues
```bash
kubectl get pvc
kubectl describe pvc <pvc-name>
```

## Development

### Local Development with Minikube

TBD

## Contributing

See [CONTRIBUTING.md](../../../.github/CONTRIBUTING.md) for more details.

### Documentation & Schema Maintenance

This chart uses automated tools to maintain documentation and schema files:

#### helm-docs
Automatically generates this README from `README.md.gotmpl` and `values.yaml` comments:

```bash
# Install helm-docs
go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest

# Generate README.md from template and values.yaml comments
helm-docs --chart-search-root=charts/dmp-roadmap
```

#### helm-schema
Automatically generates `values.schema.json` from `values.yaml`:

```bash
# Install the plugin
helm plugin install https://github.com/dadav/helm-schema

# Generate schema from values.yaml
cd charts/dmp-roadmap
helm-schema
```

#### Pre-commit Hooks
This repository includes pre-commit hooks for quality assurance and automation:

**Setup:**
```bash
# Install required tools
pip install pre-commit
go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest
helm plugin install https://github.com/dadav/helm-schema

# Install pre-commit hooks
pre-commit install

# Run on all files (first time)
pre-commit run --all-files
```

**What the hooks do:**
- **File formatting**: Remove trailing whitespace, fix end-of-file issues
- **Helm linting**: Validate chart structure and templates
- **Template validation**: Ensure Helm templates render correctly
- **Documentation generation**: Auto-update README.md from template and values.yaml
- **Schema generation**: Auto-update values.schema.json from values.yaml

**Configuration files:**
- `.pre-commit-config.yaml` - Hook configuration

**Usage:**
```bash
# Hooks run automatically on git commit
git add .
git commit -m "Update chart values"

# Run manually on specific files
pre-commit run --files charts/dmp-roadmap/values.yaml

# Update hook versions
pre-commit autoupdate
```

This ensures all chart changes maintain quality standards and keep documentation synchronized.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Homepage:** <https://dmp-pgd.ca/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| University of Alberta Library | <library.dmptool@ualberta.ca> | <https://library.ualberta.ca/> |
| University of Victoria Research Computing Services | <arcsupport@uvic.ca> | <https://www.uvic.ca/systems/researchcomputing/index.php> |

## Source Code

* <https://github.com/portagenetwork/roadmap>

## Values

### Application Configuration

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
| app.startupProbe | object | `{"failureThreshold":48,"httpGet":{"path":"/api/v1/heartbeat","port":"http"},"periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Startup probe configuration for the app |
| app.tolerations | list | `[]` | Tolerations for the app deployment |
| app.volumeMounts | list | `[]` | Additional volume mounts for the app deployment |
| app.volumes | list | `[]` | Additional volumes for the app deployment |

### Assets Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
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

### Application Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config | object | `{"application":{"dmproadmapHost":"","httpProxy":"","httpProxyPort":"","onSandbox":"false"},"environment":{"assetHost":"","baseUrl":"","bundlePath":"vendor/bundle","bundleWithout":"development:test:mysql:aws:sandbox:ci:wkhtmltopdf","defaultFunderId":8,"englishOrgId":"","frenchOrgId":"","funderOrgId":"","locale":"en_CA.UTF-8","nodeEnv":"production","omniauthFullHost":"","orcidClientMember":"false","railsEnv":"production","railsLogToStdout":"true","railsServeStaticFiles":"false","railsSkipAssetCompilation":"true","rakeEnv":"production","rollbarEnv":"production","tmpDir":"/usr/src/app/tmp","wickedPdfPath":"/usr/bin/wkhtmltopdf","wickedPdfProxy":""},"mailer":{"defaultHost":"","from":"support@example.com","smtpAddress":"smtp.example.com","smtpAuthentication":"plain","smtpDomain":"example.com","smtpPort":587,"to":"support@example.com"}}` | Configuration values for the application |
| config.application | object | `{"dmproadmapHost":"","httpProxy":"","httpProxyPort":"","onSandbox":"false"}` | Application and host settings |
| config.application.dmproadmapHost | string | global.domain.name | Main hostname for the application |
| config.application.httpProxy | string | `""` | HTTP proxy if needed |
| config.application.httpProxyPort | string | `""` | HTTP proxy port if needed |
| config.application.onSandbox | string | `"false"` | Set to true for sandbox mode |
| config.environment | object | `{"assetHost":"","baseUrl":"","bundlePath":"vendor/bundle","bundleWithout":"development:test:mysql:aws:sandbox:ci:wkhtmltopdf","defaultFunderId":8,"englishOrgId":"","frenchOrgId":"","funderOrgId":"","locale":"en_CA.UTF-8","nodeEnv":"production","omniauthFullHost":"","orcidClientMember":"false","railsEnv":"production","railsLogToStdout":"true","railsServeStaticFiles":"false","railsSkipAssetCompilation":"true","rakeEnv":"production","rollbarEnv":"production","tmpDir":"/usr/src/app/tmp","wickedPdfPath":"/usr/bin/wkhtmltopdf","wickedPdfProxy":""}` | Environment-specific settings |
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
| config.environment.rollbarEnv | string | `"production"` | Rollbar environment |
| config.environment.tmpDir | string | `"/usr/src/app/tmp"` | Tmp directory |
| config.environment.wickedPdfPath | string | `"/usr/bin/wkhtmltopdf"` | Path to wkhtmltopdf binary |
| config.environment.wickedPdfProxy | string | `""` | Proxy for wkhtmltopdf if needed |
| config.mailer | object | `{"defaultHost":"","from":"support@example.com","smtpAddress":"smtp.example.com","smtpAuthentication":"plain","smtpDomain":"example.com","smtpPort":587,"to":"support@example.com"}` | Mailer and SMTP settings |
| config.mailer.defaultHost | string | https://global.domain.name | Default host for mailer |
| config.mailer.from | string | `"support@example.com"` | From address for emails |
| config.mailer.smtpAddress | string | `"smtp.example.com"` | SMTP server address |
| config.mailer.smtpAuthentication | string | `"plain"` | SMTP authentication method |
| config.mailer.smtpDomain | string | `"example.com"` | SMTP domain |
| config.mailer.smtpPort | int | `587` | SMTP port |
| config.mailer.to | string | `"support@example.com"` | To address for system emails |

### CronJobs Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cronjobs | object | `{"researchDataOutput":{"affinity":{},"concurrencyPolicy":"Forbid","enabled":true,"env":[],"failedJobsHistoryLimit":1,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"priorityClassName":"","resources":{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartPolicy":"OnFailure","schedule":"0 1 * * *","successfulJobsHistoryLimit":3,"suspend":false,"tolerations":[],"volumeMounts":[],"volumes":[]},"statBuild":{"affinity":{},"concurrencyPolicy":"Forbid","enabled":true,"env":[],"failedJobsHistoryLimit":1,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"priorityClassName":"","resources":{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartPolicy":"OnFailure","schedule":"1 1 * * *","successfulJobsHistoryLimit":3,"suspend":false,"tolerations":[],"volumeMounts":[],"volumes":[]},"translationSync":{"affinity":{},"concurrencyPolicy":"Forbid","enabled":true,"env":[],"failedJobsHistoryLimit":1,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"priorityClassName":"","resources":{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartPolicy":"OnFailure","schedule":"0 1 * * *","successfulJobsHistoryLimit":3,"suspend":false,"tolerations":[],"volumeMounts":[],"volumes":[]}}` | Scheduled tasks for the application |
| cronjobs.researchDataOutput | object | `{"affinity":{},"concurrencyPolicy":"Forbid","enabled":true,"env":[],"failedJobsHistoryLimit":1,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"priorityClassName":"","resources":{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartPolicy":"OnFailure","schedule":"0 1 * * *","successfulJobsHistoryLimit":3,"suspend":false,"tolerations":[],"volumeMounts":[],"volumes":[]}` | Research Data Output CronJob configuration |
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
| cronjobs.researchDataOutput.schedule | string | `"0 1 * * *"` | Schedule for the CronJob (cron format) |
| cronjobs.researchDataOutput.successfulJobsHistoryLimit | int | `3` | Number of successful job history to keep |
| cronjobs.researchDataOutput.suspend | bool | `false` | Whether to suspend the job execution |
| cronjobs.researchDataOutput.tolerations | list | app.tolerations | Tolerations for the CronJob |
| cronjobs.researchDataOutput.volumeMounts | list | `[]` | Additional volume mounts for the CronJob |
| cronjobs.researchDataOutput.volumes | list | `[]` | Additional volumes for the CronJob |
| cronjobs.statBuild | object | `{"affinity":{},"concurrencyPolicy":"Forbid","enabled":true,"env":[],"failedJobsHistoryLimit":1,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"priorityClassName":"","resources":{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartPolicy":"OnFailure","schedule":"1 1 * * *","successfulJobsHistoryLimit":3,"suspend":false,"tolerations":[],"volumeMounts":[],"volumes":[]}` | Stat Build CronJob configuration |
| cronjobs.statBuild.affinity | object | app.affinity | Affinity rules for the CronJob |
| cronjobs.statBuild.concurrencyPolicy | string | `"Forbid"` | Concurrency policy for CronJob (Allow, Forbid, Replace) |
| cronjobs.statBuild.enabled | bool | `true` | Enable or disable the stat build CronJob |
| cronjobs.statBuild.env | list | `[]` | Additional environment variables for the CronJob |
| cronjobs.statBuild.failedJobsHistoryLimit | int | `1` | Number of failed job history to keep |
| cronjobs.statBuild.nodeSelector | object | app.nodeSelector | Node selector for the CronJob |
| cronjobs.statBuild.podAnnotations | object | `{}` | Pod annotations for the CronJob pods |
| cronjobs.statBuild.podLabels | object | `{}` | Pod labels for the CronJob pods |
| cronjobs.statBuild.priorityClassName | string | app.priorityClassName or global.priorityClassName | Priority class name for the CronJob |
| cronjobs.statBuild.resources | object | `{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}}` | Resource limits and requests for the CronJob |
| cronjobs.statBuild.restartPolicy | string | `"OnFailure"` | Restart policy for the job pods |
| cronjobs.statBuild.schedule | string | `"1 1 * * *"` | Schedule for the CronJob (cron format) |
| cronjobs.statBuild.successfulJobsHistoryLimit | int | `3` | Number of successful job history to keep |
| cronjobs.statBuild.suspend | bool | `false` | Whether to suspend the job execution |
| cronjobs.statBuild.tolerations | list | app.tolerations | Tolerations for the CronJob |
| cronjobs.statBuild.volumeMounts | list | `[]` | Additional volume mounts for the CronJob |
| cronjobs.statBuild.volumes | list | `[]` | Additional volumes for the CronJob |
| cronjobs.translationSync | object | `{"affinity":{},"concurrencyPolicy":"Forbid","enabled":true,"env":[],"failedJobsHistoryLimit":1,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"priorityClassName":"","resources":{"limits":{"cpu":"200m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartPolicy":"OnFailure","schedule":"0 1 * * *","successfulJobsHistoryLimit":3,"suspend":false,"tolerations":[],"volumeMounts":[],"volumes":[]}` | Translation Sync CronJob configuration |
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
| cronjobs.translationSync.schedule | string | `"0 1 * * *"` | Schedule for the CronJob (cron format) |
| cronjobs.translationSync.successfulJobsHistoryLimit | int | `3` | Number of successful job history to keep |
| cronjobs.translationSync.suspend | bool | `false` | Whether to suspend the job execution |
| cronjobs.translationSync.tolerations | list | app.tolerations | Tolerations for the CronJob |
| cronjobs.translationSync.volumeMounts | list | `[]` | Additional volume mounts for the CronJob |
| cronjobs.translationSync.volumes | list | `[]` | Additional volumes for the CronJob |

### Database Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| externalDatabase | object | `{"database":"dmp_roadmap_production","existingSecret":"","existingSecretPasswordKey":"password","host":"localhost","password":"","port":5432,"username":"dmp_roadmap"}` | External database configuration |
| externalDatabase.database | string | `"dmp_roadmap_production"` | Database name |
| externalDatabase.existingSecret | string | `""` | Name of existing secret to use for database credentials |
| externalDatabase.existingSecretPasswordKey | string | `"password"` | Key in the existing secret containing the password |
| externalDatabase.host | string | `"localhost"` | Database host |
| externalDatabase.password | string | `""` | Database password (recommend using existingSecret instead) |
| externalDatabase.port | int | `5432` | Database port |
| externalDatabase.username | string | `"dmp_roadmap"` | Database user |

### Additional Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraObjects | list | `[]` | Extra Kubernetes objects to deploy |

### Global parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.additionalLabels | object | `{}` | Common labels for the all resources |
| global.deploymentAnnotations | object | `{}` | Annotations for the all deployed Deployments |
| global.domain | object | `{"name":"example.com","path":"","prefix":""}` | Global domain configuration |
| global.domain.name | string | `"example.com"` | Main domain name used throughout the chart |
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

### Ingress Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ingress.annotations | object | `{}` | Annotations for the ingress resource |
| ingress.certManager | object | `{"acme":{"dns01":{"cloudflare":{"apiTokenSecretRef":{"key":"CF_API_KEY","name":""},"email":"support@example.com"},"enabled":false},"email":"support@example.com","http01":{"enabled":false,"ingressClass":""},"server":"https://acme-v02.api.letsencrypt.org/directory"},"annotations":{},"ca":{"secretName":""},"certificateRequestPolicy":{"allowed":{"commonName":"","dnsNames":[],"usages":["server auth","digital signature","key encipherment"]},"constraints":{"privateKey":{"algorithm":"RSA","minSize":2048}},"enabled":false,"name":""},"clusterIssuer":"","enabled":false,"issuer":"","rbac":{"certManagerNamespace":"cert-manager","enabled":false,"policyNames":[],"roleBindingName":"","roleName":"","subjects":[]},"vault":{"auth":{},"path":"","server":""}}` | Automatic TLS certificate management with cert-manager |
| ingress.certManager.acme | object | `{"dns01":{"cloudflare":{"apiTokenSecretRef":{"key":"CF_API_KEY","name":""},"email":"support@example.com"},"enabled":false},"email":"support@example.com","http01":{"enabled":false,"ingressClass":""},"server":"https://acme-v02.api.letsencrypt.org/directory"}` | ACME configuration for Let's Encrypt |
| ingress.certManager.acme.dns01 | object | `{"cloudflare":{"apiTokenSecretRef":{"key":"CF_API_KEY","name":""},"email":"support@example.com"},"enabled":false}` | DNS-01 challenge configuration |
| ingress.certManager.acme.dns01.cloudflare | object | `{"apiTokenSecretRef":{"key":"CF_API_KEY","name":""},"email":"support@example.com"}` | Cloudflare DNS-01 configuration |
| ingress.certManager.acme.dns01.cloudflare.apiTokenSecretRef | object | `{"key":"CF_API_KEY","name":""}` | Cloudflare API token secret reference |
| ingress.certManager.acme.dns01.cloudflare.apiTokenSecretRef.key | string | `"CF_API_KEY"` | Secret key containing Cloudflare API token |
| ingress.certManager.acme.dns01.cloudflare.apiTokenSecretRef.name | string | `""` | Secret name containing Cloudflare API token |
| ingress.certManager.acme.dns01.cloudflare.email | string | `"support@example.com"` | Cloudflare email |
| ingress.certManager.acme.dns01.enabled | bool | `false` | Enable DNS-01 challenge |
| ingress.certManager.acme.email | string | `"support@example.com"` | Email address for ACME registration |
| ingress.certManager.acme.http01 | object | `{"enabled":false,"ingressClass":""}` | HTTP-01 challenge configuration |
| ingress.certManager.acme.http01.enabled | bool | `false` | Enable HTTP-01 challenge |
| ingress.certManager.acme.http01.ingressClass | string | `""` | Ingress class for HTTP-01 challenge |
| ingress.certManager.acme.server | string | `"https://acme-v02.api.letsencrypt.org/directory"` | ACME server URL |
| ingress.certManager.annotations | object | `{}` | Additional annotations for cert-manager |
| ingress.certManager.ca | object | `{"secretName":""}` | CA issuer configuration |
| ingress.certManager.ca.secretName | string | `""` | Secret name containing CA certificate and private key |
| ingress.certManager.certificateRequestPolicy | object | `{"allowed":{"commonName":"","dnsNames":[],"usages":["server auth","digital signature","key encipherment"]},"constraints":{"privateKey":{"algorithm":"RSA","minSize":2048}},"enabled":false,"name":""}` | Certificate Request Policy configuration |
| ingress.certManager.certificateRequestPolicy.allowed | object | `{"commonName":"","dnsNames":[],"usages":["server auth","digital signature","key encipherment"]}` | Allowed certificate properties |
| ingress.certManager.certificateRequestPolicy.allowed.commonName | string | `""` | Common name for certificates |
| ingress.certManager.certificateRequestPolicy.allowed.dnsNames | list | `[]` | DNS names allowed for certificates |
| ingress.certManager.certificateRequestPolicy.allowed.usages | list | `["server auth","digital signature","key encipherment"]` | Certificate usage constraints |
| ingress.certManager.certificateRequestPolicy.constraints | object | `{"privateKey":{"algorithm":"RSA","minSize":2048}}` | Certificate constraints |
| ingress.certManager.certificateRequestPolicy.constraints.privateKey | object | `{"algorithm":"RSA","minSize":2048}` | Private key constraints |
| ingress.certManager.certificateRequestPolicy.constraints.privateKey.algorithm | string | `"RSA"` | Private key algorithm |
| ingress.certManager.certificateRequestPolicy.constraints.privateKey.minSize | int | `2048` | Minimum private key size |
| ingress.certManager.certificateRequestPolicy.enabled | bool | `false` | Enable Certificate Request Policy |
| ingress.certManager.certificateRequestPolicy.name | string | `""` | Name for the Certificate Request Policy |
| ingress.certManager.clusterIssuer | string | `""` | ClusterIssuer name (for cluster-scoped issuer) |
| ingress.certManager.enabled | bool | `false` | Enable automatic TLS certificate management |
| ingress.certManager.issuer | string | `""` | Issuer name (for namespace-scoped issuer) |
| ingress.certManager.rbac | object | `{"certManagerNamespace":"cert-manager","enabled":false,"policyNames":[],"roleBindingName":"","roleName":"","subjects":[]}` | RBAC configuration for cert-manager policies |
| ingress.certManager.rbac.certManagerNamespace | string | `"cert-manager"` | cert-manager namespace (where cert-manager ServiceAccount is located) |
| ingress.certManager.rbac.enabled | bool | `false` | Enable RBAC for cert-manager policies |
| ingress.certManager.rbac.policyNames | list | `[]` | Policy names that can be used |
| ingress.certManager.rbac.roleBindingName | string | `""` | RoleBinding name for cert-manager policy access |
| ingress.certManager.rbac.roleName | string | `""` | Role name for cert-manager policy access |
| ingress.certManager.rbac.subjects | list | `[]` | Custom subjects for the RoleBinding |
| ingress.certManager.vault | object | `{"auth":{},"path":"","server":""}` | Vault issuer configuration |
| ingress.certManager.vault.auth | object | `{}` | Vault authentication configuration |
| ingress.certManager.vault.path | string | `""` | Vault path for certificate signing |
| ingress.certManager.vault.server | string | `""` | Vault server URL |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable or disable the ingress |
| ingress.hosts | list | `[]` | Hosts configuration (if empty, uses global.domain.name) |
| ingress.tls | list | `[]` | TLS configuration for the ingress |

### Network Policies

| Key | Type | Default | Description |
|-----|------|---------|-------------|
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

### Storage Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| storage | object | `{"cephfs":{"accessModes":["ReadWriteMany"],"monitors":[],"persistentVolumeReclaimPolicy":"Retain","volumeMode":"Filesystem","volumes":{"locales":{"mountPath":"/usr/src/app/config/locale","path":"","secretRef":"cephfs-locales-key","size":"5Gi"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","path":"","secretRef":"cephfs-uploads-key","size":"5Gi"}}},"emptyDir":{"volumes":{"locales":{"mountPath":"/usr/src/app/config/locale","sizeLimit":"1Gi"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","sizeLimit":"5Gi"}}},"hostPath":{"volumes":{"locales":{"mountPath":"/usr/src/app/config/locale","path":"/data/dmp-roadmap/locales","type":"DirectoryOrCreate"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","path":"/data/dmp-roadmap/uploads","type":"DirectoryOrCreate"}}},"nfs":{"server":"","volumes":{"locales":{"mountPath":"/usr/src/app/config/locale","path":"/data/dmp-roadmap/locales"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","path":"/data/dmp-roadmap/uploads"}}},"pvc":{"accessModes":["ReadWriteOnce"],"persistentVolumeReclaimPolicy":"Retain","storageClassName":"","volumeMode":"Filesystem","volumes":{"locales":{"accessModes":["ReadWriteMany"],"mountPath":"/usr/src/app/config/locale","size":"5Gi"},"uploads":{"accessModes":[],"mountPath":"/usr/src/app/public/system/dragonfly","size":"5Gi"}}},"type":"pvc"}` | Storage configuration for the application |
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
| storage.emptyDir | object | `{"volumes":{"locales":{"mountPath":"/usr/src/app/config/locale","sizeLimit":"1Gi"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","sizeLimit":"5Gi"}}}` | EmptyDir storage configuration (temporary, data lost on pod restart) |
| storage.emptyDir.volumes | object | `{"locales":{"mountPath":"/usr/src/app/config/locale","sizeLimit":"1Gi"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","sizeLimit":"5Gi"}}` | Volume definitions for emptyDir |
| storage.emptyDir.volumes.locales | object | `{"mountPath":"/usr/src/app/config/locale","sizeLimit":"1Gi"}` | Locales volume configuration |
| storage.emptyDir.volumes.locales.mountPath | string | `"/usr/src/app/config/locale"` | Mount path for the locales volume |
| storage.emptyDir.volumes.locales.sizeLimit | string | `"1Gi"` | Size limit for the volume |
| storage.emptyDir.volumes.uploads | object | `{"mountPath":"/usr/src/app/public/system/dragonfly","sizeLimit":"5Gi"}` | Uploads volume configuration |
| storage.emptyDir.volumes.uploads.mountPath | string | `"/usr/src/app/public/system/dragonfly"` | Mount path for the uploads volume |
| storage.emptyDir.volumes.uploads.sizeLimit | string | `"5Gi"` | Size limit for the volume |
| storage.hostPath | object | `{"volumes":{"locales":{"mountPath":"/usr/src/app/config/locale","path":"/data/dmp-roadmap/locales","type":"DirectoryOrCreate"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","path":"/data/dmp-roadmap/uploads","type":"DirectoryOrCreate"}}}` | Host path storage configuration |
| storage.hostPath.volumes | object | `{"locales":{"mountPath":"/usr/src/app/config/locale","path":"/data/dmp-roadmap/locales","type":"DirectoryOrCreate"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","path":"/data/dmp-roadmap/uploads","type":"DirectoryOrCreate"}}` | Volume definitions for hostPath |
| storage.hostPath.volumes.locales | object | `{"mountPath":"/usr/src/app/config/locale","path":"/data/dmp-roadmap/locales","type":"DirectoryOrCreate"}` | Locales volume configuration |
| storage.hostPath.volumes.locales.mountPath | string | `"/usr/src/app/config/locale"` | Mount path for the locales volume |
| storage.hostPath.volumes.locales.path | string | `"/data/dmp-roadmap/locales"` | Path on the host |
| storage.hostPath.volumes.locales.type | string | `"DirectoryOrCreate"` | Host path type |
| storage.hostPath.volumes.uploads | object | `{"mountPath":"/usr/src/app/public/system/dragonfly","path":"/data/dmp-roadmap/uploads","type":"DirectoryOrCreate"}` | Uploads volume configuration |
| storage.hostPath.volumes.uploads.mountPath | string | `"/usr/src/app/public/system/dragonfly"` | Mount path for the uploads volume |
| storage.hostPath.volumes.uploads.path | string | `"/data/dmp-roadmap/uploads"` | Path on the host |
| storage.hostPath.volumes.uploads.type | string | `"DirectoryOrCreate"` | Host path type |
| storage.nfs | object | `{"server":"","volumes":{"locales":{"mountPath":"/usr/src/app/config/locale","path":"/data/dmp-roadmap/locales"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","path":"/data/dmp-roadmap/uploads"}}}` | NFS storage configuration |
| storage.nfs.server | string | `""` | NFS server address |
| storage.nfs.volumes | object | `{"locales":{"mountPath":"/usr/src/app/config/locale","path":"/data/dmp-roadmap/locales"},"uploads":{"mountPath":"/usr/src/app/public/system/dragonfly","path":"/data/dmp-roadmap/uploads"}}` | Volume definitions for NFS |
| storage.nfs.volumes.locales | object | `{"mountPath":"/usr/src/app/config/locale","path":"/data/dmp-roadmap/locales"}` | Locales volume configuration |
| storage.nfs.volumes.locales.mountPath | string | `"/usr/src/app/config/locale"` | Mount path for the locales volume |
| storage.nfs.volumes.locales.path | string | `"/data/dmp-roadmap/locales"` | Path on the NFS server |
| storage.nfs.volumes.uploads | object | `{"mountPath":"/usr/src/app/public/system/dragonfly","path":"/data/dmp-roadmap/uploads"}` | Uploads volume configuration |
| storage.nfs.volumes.uploads.mountPath | string | `"/usr/src/app/public/system/dragonfly"` | Mount path for the uploads volume |
| storage.nfs.volumes.uploads.path | string | `"/data/dmp-roadmap/uploads"` | Path on the NFS server |
| storage.pvc | object | `{"accessModes":["ReadWriteOnce"],"persistentVolumeReclaimPolicy":"Retain","storageClassName":"","volumeMode":"Filesystem","volumes":{"locales":{"accessModes":["ReadWriteMany"],"mountPath":"/usr/src/app/config/locale","size":"5Gi"},"uploads":{"accessModes":[],"mountPath":"/usr/src/app/public/system/dragonfly","size":"5Gi"}}}` | Standard PVC storage configuration |
| storage.pvc.accessModes | list | `["ReadWriteOnce"]` | Access modes for the volumes |
| storage.pvc.persistentVolumeReclaimPolicy | string | `"Retain"` | Storage reclaim policy |
| storage.pvc.storageClassName | string | `""` | Storage class name (leave empty for default) |
| storage.pvc.volumeMode | string | `"Filesystem"` | Volume mode |
| storage.pvc.volumes | object | `{"locales":{"accessModes":["ReadWriteMany"],"mountPath":"/usr/src/app/config/locale","size":"5Gi"},"uploads":{"accessModes":[],"mountPath":"/usr/src/app/public/system/dragonfly","size":"5Gi"}}` | Volume definitions for PVC |
| storage.pvc.volumes.locales | object | `{"accessModes":["ReadWriteMany"],"mountPath":"/usr/src/app/config/locale","size":"5Gi"}` | Locales volume configuration (shared between app and cronjobs) |
| storage.pvc.volumes.locales.accessModes | list | `["ReadWriteMany"]` | Access modes (needs ReadWriteMany for sharing between pods) |
| storage.pvc.volumes.locales.mountPath | string | `"/usr/src/app/config/locale"` | Mount path for the locales volume |
| storage.pvc.volumes.locales.size | string | `"5Gi"` | Size for the locales volume |
| storage.pvc.volumes.uploads | object | `{"accessModes":[],"mountPath":"/usr/src/app/public/system/dragonfly","size":"5Gi"}` | Uploads volume configuration |
| storage.pvc.volumes.uploads.accessModes | list | `[]` | Access modes (override global if needed) |
| storage.pvc.volumes.uploads.mountPath | string | `"/usr/src/app/public/system/dragonfly"` | Mount path for the uploads volume |
| storage.pvc.volumes.uploads.size | string | `"5Gi"` | Size for the uploads volume |
| storage.type | string | `"pvc"` | Storage type (pvc, cephfs, hostPath, nfs, emptyDir) |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | String to fully override `dmp-roadmap.fullname` |
| nameOverride | string | `""` | Provide a name in place of `dmp-roadmap` |
| namespaceOverride | string | `.Release.Namespace` | Override the namespace |
