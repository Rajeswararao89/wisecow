#!/bin/bash

echo "TLS Setup Verification"
echo "======================"

echo "1. Checking Ingress Controller..."
kubectl get pods -n ingress-nginx

echo ""
echo "2. Checking Ingress..."
kubectl get ingress wisecow-ingress

echo ""
echo "3. Checking TLS Secret..."
kubectl get secret wisecow-tls

echo ""
echo "4. Testing direct HTTPS access..."
if curl -ks https://wisecow.local > /dev/null; then
    echo "SUCCESS: Direct HTTPS access working!"
    echo "Response preview:"
    curl -ks https://wisecow.local | head -3
else
    echo "Trying alternative access method..."

    # Try port-forward method
    kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8443:443 2>/dev/null &
    PF_PID=$!
    sleep 3

    if curl -ks https://localhost:8443/ -H "Host: wisecow.local" > /dev/null; then
        echo "SUCCESS: HTTPS working via port-forward!"
        curl -ks https://localhost:8443/ -H "Host: wisecow.local" | head -3
    else
        echo "FAILED: HTTPS not accessible"
        kill $PF_PID 2>/dev/null
        exit 1
    fi
    kill $PF_PID 2>/dev/null
fi

echo ""
echo "5. Testing HTTP to HTTPS redirect..."
redirect_status=$(curl -s -o /dev/null -w "%{http_code}" http://wisecow.local)
if [ "$redirect_status" = "308" ] || [ "$redirect_status" = "301" ]; then
    echo "SUCCESS: HTTP redirects to HTTPS ($redirect_status)"
else
    echo "Redirect test returned: $redirect_status"
fi

echo ""
echo "TLS verification complete!"
