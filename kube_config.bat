@echo off
SET OUTPUT=%tmp%\_
kubectl config view --minify -o jsonpath={.clusters[0].cluster.server} > %OUTPUT%
SET /P server=< %OUTPUT%
SET team=team-slick-checkout

kubectl get sa/%team% -o yaml -o jsonpath="{.secrets[*].name}" > %OUTPUT%
SET /P name=< %OUTPUT%

kubectl get secret/%name% -o jsonpath="{.data.ca\.crt}" > %OUTPUT%
SET /P ca=< %OUTPUT%

kubectl get secret/%name% -o jsonpath="{.data.token}" | base64 --decode > %OUTPUT%
SET /P token=< %OUTPUT%

kubectl get secret/%name% -o jsonpath="{.data.namespace}" > %OUTPUT%
SET /P namespace=< %OUTPUT%
del %OUTPUT%

set n=^&echo.
(
  echo apiVersion: v1%n%^
kind: Config%n%^
clusters:%n%^
- name: aks-cluster%n%^
  cluster:%n%^
    certificate-authority-data: %ca%%n%^
    server: %server%%n%^
contexts:%n%^
- name: aks-context%n%^
  context:%n%^
    cluster: aks-cluster%n%^
    namespace: %namespace%%n%^
    user: aks-team%n%^
current-context: aks-context%n%^
users:%n%^
- name: aks-team%n%^
  user:%n%^
    token: %token% %n%
) > %team%.kubeconfig
