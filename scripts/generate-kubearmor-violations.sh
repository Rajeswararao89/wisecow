#!/bin/bash

echo "KubeArmor Violation Generator for WiseCow"
echo "=========================================="

# Check if KubeArmor is running
echo "1. Checking KubeArmor status..."
kubectl get pods -n kube-system | grep kubearmor

echo ""
echo "2. Current KubeArmor policies:"
kubectl get kubearmorpolicy -A

echo ""
echo "3. Generating policy violations..."

# Commands that should trigger violations
violation_commands=(
  "ls /etc/passwd"
  "cat /etc/hosts"
  "whoami"
  "ps aux"
  "ls /usr/bin/"
  "touch /tmp/testfile"
  "curl http://google.com"
)

for cmd in "${violation_commands[@]}"; do
  echo "Attempting: $cmd"
  kubectl exec -it deployment/wisecow -- /bin/bash -c "$cmd" 2>&1 | head -1
  sleep 2
done

echo ""
echo "4. Checking KubeArmor logs for violations..."
echo "Wait for 10 seconds for logs to populate..."
sleep 10

kubectl logs -l app=kubearmor -n kube-system --tail=100 | grep -A2 -B2 "wisecow" | head -20

echo ""
echo "5. If no violations shown, check KubeArmor events:"
kubectl get events -n kube-system --field-selector involvedObject.name=kubearmor --tail=10

echo ""
echo "Violation generation complete!"
