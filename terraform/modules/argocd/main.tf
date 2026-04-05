resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = kubernetes_namespace_v1.argocd.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [yamlencode({
    configs = {
      params = {
        # Run without TLS — the ALB ingress terminates TLS externally.
        "server.insecure" = true
      }
      secret = {
        argocdServerAdminPassword = var.argocd_admin_password_bcrypt
      }
      webhook = {
        github = {
          secret = var.argocd_webhook_secret
        }
      }
    }

    server = {
      service = {
        type = "ClusterIP"
      }
    }
  })]

  depends_on = [kubernetes_namespace_v1.argocd]
}

resource "kubernetes_secret_v1" "argocd_repo" {
  metadata {
    name      = "repo-${var.project_name}"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.repo_url
    username = "git"
    password = var.github_token
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "argocd_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = var.project_name
      namespace = kubernetes_namespace_v1.argocd.metadata[0].name
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }

    spec = {
      project = "default"

      source = {
        repoURL        = var.repo_url
        targetRevision = var.target_revision
        path           = "kubernetes/overlays/${var.environment}"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "devops-app"
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "ApplyOutOfSyncOnly=true",
          "ServerSideApply=true",
        ]
        retry = {
          limit = 5
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "3m"
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_secret_v1.argocd_repo,
  ]
}
