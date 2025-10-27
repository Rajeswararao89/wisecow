## Overview
Zero-trust security policy for the WiseCow application using KubeArmor to enforce least privilege access.

## Policy Details

### Policy 1: Zero-Trust Allow Policy
- **File**: `kubernetes/kubearmor-policy.yaml`
- **Strategy**: Allow-list specific paths only
- **Scope**: WiseCow application pods

### Policy 2: Restrictive Block Policy  
- **File**: `kubernetes/kubearmor-restrictive-policy.yaml`
- **Strategy**: Block unnecessary directories and commands
- **Purpose**: Generate security violations for demonstration

## Key Security Controls

### File Access Restrictions
- Only allow: `/usr/local/bin/wisecow.sh`, `/usr/games/cowsay`, `/usr/games/fortune`, `/bin/nc`, `/bin/bash`
- Block recursive access to: `/etc/`, `/var/`, `/usr/bin/`, `/bin/`

### Process Execution Restrictions
- Only allow essential processes for WiseCow operation
- Block all other process executions

### Network Restrictions
- Only allow TCP port 4499 for WiseCow service
- Block all other network connections

## Expected Violations
The restrictive policy will generate security violations when:
- Accessing system directories (`/etc/`, `/var/`)
- Executing unauthorized commands
- Accessing blocked network ports

## Implementation Notes
- Policies use label selectors to target WiseCow deployment
- Severity levels indicate security importance
- Tags help with policy management and auditing

## Usage
```bash
# Apply policies
kubectl apply -f kubernetes/kubearmor-policy.yaml
kubectl apply -f kubernetes/kubearmor-restrictive-policy.yaml

# Check violations
kubectl logs -l app=kubearmor -n kube-system | grep violation
C
