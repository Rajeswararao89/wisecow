#!/usr/bin/env python3
"""
WiseCow Application Health Checker
Checks WiseCow application uptime and HTTP status codes
"""

import requests
import time
import sys
import subprocess
from datetime import datetime

class WiseCowHealthChecker:
    def __init__(self):
        self.results = []
        self.healthy_count = 0
        self.total_checks = 0
        
    def check_application(self, url, name, timeout=10):
        """Check if application is up and functioning correctly"""
        self.total_checks += 1
        
        try:
            start_time = time.time()
            response = requests.get(url, timeout=timeout, verify=False)
            response_time = time.time() - start_time
            
            status_code = response.status_code
            
            # Check if response contains WiseCow content
            content_check = "wise" in response.text.lower() or "cow" in response.text.lower() or "pre" in response.text.lower()
            
            if 200 <= status_code < 400 and content_check:
                status = "UP"
                self.healthy_count += 1
                message = f"Status {status_code} - WiseCow is functioning correctly"
            elif 200 <= status_code < 400:
                status = "DEGRADED"
                message = f"Status {status_code} - Responding but content may be incorrect"
            else:
                status = "DOWN"
                message = f"Status {status_code} - WiseCow is not responding properly"
                
            result = {
                'name': name,
                'url': url,
                'status': status,
                'status_code': status_code,
                'response_time': round(response_time, 2),
                'message': message,
                'timestamp': datetime.now().isoformat()
            }
            
            self.results.append(result)
            
            # Console output
            if status == "UP":
                print(f"UP: {name} - {message} ({response_time:.2f}s)")
            elif status == "DEGRADED":
                print(f"DEGRADED: {name} - {message} ({response_time:.2f}s)")
            else:
                print(f"DOWN: {name} - {message} ({response_time:.2f}s)")
                
            return status == "UP"
            
        except requests.exceptions.RequestException as e:
            result = {
                'name': name,
                'url': url,
                'status': "DOWN",
                'status_code': None,
                'response_time': None,
                'message': f"Connection failed: {str(e)}",
                'timestamp': datetime.now().isoformat()
            }
            
            self.results.append(result)
            print(f"DOWN: {name} - Connection failed: {str(e)}")
            return False
    
    def check_wisecow_endpoints(self):
        """Check all WiseCow application endpoints"""
        applications = [
            {
                'name': 'WiseCow Local HTTP',
                'url': 'http://localhost:8080',
                'timeout': 10
            },
            {
                'name': 'WiseCow HTTPS',
                'url': 'https://wisecow.local', 
                'timeout': 10
            },
            {
                'name': 'WiseCow Service Direct',
                'url': 'http://localhost:4499',
                'timeout': 10
            }
        ]
        
        print("Checking WiseCow Application Endpoints...")
        print("=" * 60)
        
        all_healthy = True
        
        for app in applications:
            healthy = self.check_application(
                app['url'], 
                app['name'], 
                app.get('timeout', 10)
            )
            if not healthy:
                all_healthy = False
                
        return all_healthy
    
    def check_kubernetes_status(self):
        """Check Kubernetes WiseCow deployment status"""
        print("\nChecking Kubernetes WiseCow Deployment...")
        print("-" * 40)
        
        try:
            # Check if kubectl is available
            result = subprocess.run(['kubectl', 'version', '--client'], 
                                  capture_output=True, text=True, timeout=5)
            
            if result.returncode == 0:
                # Check WiseCow deployment
                result = subprocess.run([
                    'kubectl', 'get', 'deployment', 'wisecow', 
                    '-o', 'jsonpath={.status.readyReplicas}/{.status.replicas}'
                ], capture_output=True, text=True, timeout=10)
                
                if result.returncode == 0 and result.stdout:
                    ready_replicas, total_replicas = result.stdout.split('/')
                    ready_replicas = int(ready_replicas) if ready_replicas else 0
                    total_replicas = int(total_replicas) if total_replicas else 0
                    
                    if ready_replicas == total_replicas and total_replicas > 0:
                        status = "UP"
                        message = f"All {ready_replicas}/{total_replicas} pods ready"
                        self.healthy_count += 1
                    else:
                        status = "DEGRADED" 
                        message = f"Only {ready_replicas}/{total_replicas} pods ready"
                    
                    result = {
                        'name': 'Kubernetes Deployment',
                        'url': 'N/A',
                        'status': status,
                        'status_code': None,
                        'response_time': None,
                        'message': message,
                        'timestamp': datetime.now().isoformat()
                    }
                    
                    self.results.append(result)
                    self.total_checks += 1
                    
                    if status == "UP":
                        print(f"UP: Kubernetes Deployment - {message}")
                    else:
                        print(f"DEGRADED: Kubernetes Deployment - {message}")
                        
                    return status == "UP"
                
            else:
                print("INFO: kubectl not available - skipping Kubernetes check")
                
        except (subprocess.TimeoutExpired, subprocess.SubprocessError, ValueError) as e:
            print(f"INFO: Kubernetes check failed - {str(e)}")
        
        return True  # Don't fail overall if Kubernetes check fails
    
    def generate_report(self):
        """Generate WiseCow health check report"""
        success_rate = (self.healthy_count / self.total_checks) * 100 if self.total_checks > 0 else 0
        
        print("\n" + "=" * 60)
        print("WISECOW APPLICATION HEALTH CHECK REPORT")
        print("=" * 60)
        print(f"Timestamp: {datetime.now().isoformat()}")
        print(f"Application: WiseCow")
        print(f"Total Checks: {self.total_checks}")
        print(f"Healthy Checks: {self.healthy_count}")
        print(f"Unhealthy Checks: {self.total_checks - self.healthy_count}")
        print(f"Success Rate: {success_rate:.1f}%")
        
        print("\nDetailed Results:")
        print("-" * 60)
        for result in self.results:
            status_display = result['status'].ljust(8)
            time_str = f"({result['response_time']}s)" if result['response_time'] else ""
            print(f"{status_display}: {result['name']}")
            print(f"         URL: {result['url']}")
            if result['status_code']:
                print(f"         Status Code: {result['status_code']}")
            print(f"         Message: {result['message']} {time_str}")
            print()

def main():
    checker = WiseCowHealthChecker()
    
    # Run WiseCow specific health checks
    endpoints_healthy = checker.check_wisecow_endpoints()
    kubernetes_healthy = checker.check_kubernetes_status()
    
    # Generate report
    checker.generate_report()
    
    # Exit with appropriate code
    all_healthy = endpoints_healthy and kubernetes_healthy
    
    if all_healthy:
        print("OVERALL STATUS: WISECOW APPLICATION IS UP AND FUNCTIONING CORRECTLY")
        sys.exit(0)
    else:
        print("OVERALL STATUS: WISECOW APPLICATION HAS ISSUES - REVIEW THE REPORT")
        sys.exit(1)

if __name__ == "__main__":
    main()
