@echo off
SET OUTPUT=%tmp%\_
kubectl config view --minify -o jsonpath={.clusters[0].cluster.server} > %OUTPUT%
SET /P server=< %OUTPUT%
SET team=team-slick-checkout

kubectl get sa/%team% -o yaml -o jsonpath="{.secrets[0].name}" > %OUTPUT%
SET /P name=< %OUTPUT%

kubectl get secret/%name% -o jsonpath="{.data.ca\.crt}" > %OUTPUT%
SET /P ca=< %OUTPUT%

kubectl get secret/%name% -o jsonpath="{.data.token}" | base64 --decode > %OUTPUT%
SET /P token=< %OUTPUT%

kubectl get secret/%name% -o jsonpath="{.data.namespace}" | base64 --decode > %OUTPUT%
SET /P namespace=< %OUTPUT%
del %OUTPUT%

set n=^&echo.
(
  echo apiVersion: v1%n%^
  kind: Config%n%^
  clusters:%n%^
  - name: aks-team%n%^
    cluster:%n%^
      certificate-authority-data: %ca%%n%^
      server: %server%%n%^
  contexts:%n%^
  - name: aks-team%n%^
    context:%n%^
      cluster: aks-team%n%^
      namespace: %namespace%%n%^
      user: aks-team%n%^
  current-context: aks-team%n%^
  users:%n%^
  - name: aks-team%n%^
    user:%n%^
      token: %token% %n%
) > %team%.kubeconfig
