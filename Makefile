.PHONY: argocd-ui argocd-password cluster-up cluster-down stop-forwards

cluster-up:
	kind create cluster --config cluster/kind-config.yaml

cluster-down:
	kind delete cluster --name gitops-platform

argocd-ui:
	@pkill -f "port-forward.*argocd" 2>/dev/null || true
	@kubectl port-forward service/argocd-server -n argocd 8080:80 > /dev/null 2>&1 &
	@echo "ArgoCD UI → http://localhost:8080"

argocd-password:
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo ""

stop-forwards:
	@pkill -f "port-forward" 2>/dev/null || true
	@echo "All port-forwards stopped"