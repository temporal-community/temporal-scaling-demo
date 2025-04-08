# Temporal Scaling Demo

This repository demonstrates how to use KEDA's Temporal scaler to automatically scale Temporal workers based on a task queue's backlog. This is particularly useful for handling variable workload demands efficiently in a Kubernetes environment.

## Overview

The demo includes a multi-service application that uses Temporal for workflow orchestration. When the system experiences increased load, KEDA automatically scales the worker pods to handle the additional workflow tasks.

This demo is based on the Temporal Order Management System (OMS) reference application, which showcases a realistic e-commerce workflow orchestration scenario. The original code for the reference application can be found in these repositories:
- [Go Backend](https://github.com/temporalio/reference-app-orders-go)
- [Web Frontend](https://github.com/temporalio/reference-app-orders-web/)

## Prerequisites

- Kubernetes cluster
- Helm (v3+)

The Helm chart bundles all necessary components, so no additional tools or dependencies are required:

- Temporal Server (with Cassandra and Elasticsearch)
- KEDA
- Prometheus and Grafana for monitoring
- Demo application components (Web UI, API services, and workers)

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/temporal-community/temporal-scaling-demo.git
   cd temporal-scaling-demo
   ```

2. Create a namespace for the demo:
   ```
   kubectl create namespace scaling-demo
   ```

3. Install the Helm chart:
   ```
   helm package --dependency-update .
   helm install -n scaling-demo temporal-demo ./temporal-scaling-demo-0.1.0.tgz
   ```

4. Wait for all pods to become ready (this may take several minutes as Cassandra and Elasticsearch require time to initialize):
   ```
   kubectl get pods -n scaling-demo -w
   ```

## Accessing the Demo

Once all pods are running, access the Web UI by port-forwarding to the web service:

```
kubectl port-forward svc/temporal-demo-temporal-scaling-demo-web 8080:80 -n scaling-demo
```

Then open your browser and navigate to `http://localhost:8080`

## Using the Demo

1. Select the "Operator" role in the Web UI
2. Use the load generator on the page to generate order workflow load
3. The graphs on the page will visualize:
   - Order completion rate
   - Task queue backlog
   - Number of worker pods (this will increase when scaling occurs)

## Observing Auto-Scaling

1. Start with a low order creation rate (around 10 orders per second)
2. Gradually increase the load to 20 orders per second
3. Once the workload reaches this threshold, you'll observe:
   - The task queue backlog increasing
   - KEDA automatically scaling up the main worker pods
   - The worker count graph showing the increase in worker pods
   - The backlog being processed more quickly as additional workers come online

To observe the scaling events:

```
kubectl get horizontalpodautoscalers.autoscaling -n scaling-demo
kubectl get pods -l app.kubernetes.io/component=main-worker -n scaling-demo -w
```

## How Auto-Scaling Works

The auto-scaling in this demo is achieved through Kubernetes ScaledObjects that are created for the worker deployments. These ScaledObjects are read by KEDA, which then creates and manages HorizontalPodAutoscalers based on the metrics from Temporal task queues.

Key points about the scaling behavior:

- The main worker deployment is configured to scale based on the combined backlog of two task queues: "orders" and "shipment"
- The ScaledObject for the main worker uses a formula (`orders + shipment`) to aggregate the backlog metrics from both queues
- Both the main-worker and billing-worker deployments are configured to scale with KEDA
- The billing worker typically won't scale during the demo as it doesn't get loaded as quickly as the main worker, but it will scale if its task queue backlog increases
- Each ScaledObject defines minimum and maximum replica counts, as well as scaling behavior like stabilization windows and scaling policies

You can examine the ScaledObjects with:

```
kubectl get scaledobjects -n scaling-demo
kubectl describe scaledobject temporal-demo-main-worker -n scaling-demo
```

You can find the ScaledObject template definitions in the repository:
- [Main Worker ScaledObject](templates/main-worker-scaledobject.yaml)
- [Billing Worker ScaledObject](templates/billing-worker-scaledobject.yaml)

## Monitoring

The demo includes Prometheus and Grafana for monitoring. Access Grafana:

```
kubectl port-forward svc/temporal-demo-grafana 3000:80 -n scaling-demo
```

Default credentials:
- Username: admin
- Password: prom-operator

Note that while pre-configured Temporal dashboards aren't included in Grafana, all Temporal metrics are available via Prometheus and can be used to create custom dashboards or queries.

## Troubleshooting

- **Pods taking a long time to be ready**: Cassandra and Elasticsearch can take several minutes to initialize. Future versions may use SQL for faster startup.
- **No scaling observed**: Ensure you've generated enough load to create a backlog. The scaling threshold is designed to prevent unnecessary scaling for small, temporary backlogs.

## Clean Up

To remove the demo from your cluster:

```
helm uninstall temporal-demo -n scaling-demo
kubectl delete namespace scaling-demo
```

## Architecture

The demo consists of multiple components:
- Web UI for visualization and load generation
- Main API service for order and shipment operations
- Billing API service for payment and fraud operations
- Main worker service processing order and shipment workflows
- Billing worker service processing payment workflows
- Temporal server orchestrating all workflows
- KEDA for auto-scaling workers based on task queue metrics
- Prometheus and Grafana for monitoring

Both the main-worker and billing-worker deployments are configured to scale automatically with KEDA based on the backlog in their respective Temporal task queues.
