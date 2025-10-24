#!/bin/bash
set -e

echo "Deploying wisecow application..."

# Apply Kubernetes manifests
kubectl apply -f kubernetes/

# Wait for rollout to complete
echo "Waiting for deployment to complete..."
kubectl rollout status deployment/wisecow --timeout=300s

# Run smoke test
echo "Running smoke test..."
kubectl port-forward service/wisecow-service 8080:80 &
sleep 5

if curl -s http://localhost:8080 > /dev/null; then
    echo "Smoke test passed!"
else
    echo "Smoke test failed!"
    exit 1
fi

pkill -f "port-forward"
echo "Deployment completed successfully!"
