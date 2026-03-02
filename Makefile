.PHONY: argocd-ui argocd-password cluster-up cluster-down stop-forwards bootstrap

cluster-up:
	kind create cluster --config cluster/kind-config.yaml

cluster-down:
	kind delete cluster --name gitops-platform

bootstrap: cluster-up
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Step 1/5 — Adding Helm repos..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Step 2/5 — Installing NGINX Ingress..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	helm install ingress-nginx ingress-nginx/ingress-nginx \
		--namespace ingress-nginx --create-namespace \
		--values cluster/bootstrap/nginx-ingress-values.yaml
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Step 3/5 — Installing ArgoCD..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	helm install argocd argo/argo-cd \
		--namespace argocd --create-namespace \
		--values cluster/bootstrap/argocd/argocd-values.yaml
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Step 4/5 — Waiting for ArgoCD pods..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	kubectl wait --for=condition=ready pod \
		-l app.kubernetes.io/name=argocd-server \
		-n argocd --timeout=120s
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Step 5/5 — Applying App-of-Apps..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	kubectl apply -f platform/argocd/app-of-apps.yaml
	@echo ""
	@echo "✅ Bootstrap complete!"
	@echo ""
	@echo "  ArgoCD UI  → make argocd-ui  (then open http://localhost:8080)"
	@echo "  Password   → make argocd-password"
	@echo "  Demo app   → add '127.0.0.1 demo-app.local' to /etc/hosts"
	@echo ""

argocd-ui:
	@pkill -f "port-forward.*argocd" 2>/dev/null || true
	@kubectl port-forward service/argocd-server -n argocd 8080:80 > /dev/null 2>&1 &
	@echo "ArgoCD UI → http://localhost:8080"

argocd-password:
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo ""

stop-forwards:
	@pkill -f "port-forward" 2>/dev/null || true
	@echo "All port-forwards stopped"