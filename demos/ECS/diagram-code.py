with Diagram("ECS Fargate VPC Architecture", show=False, direction="TB", graph_attr={"splines": "ortho", "nodesep": "1.5", "ranksep": "1.2"}):
    
    users = Users("Internet\nUsers")
    
    with Cluster("AWS Cloud - us-west-2"):
        
        ecr = ECR("ECR Repository\ndemo-nodejs-app")
        logs = CloudwatchLogs("CloudWatch Logs\n/ecs/demo\n7 day retention")
        iam = IAMRole("Task Execution\nRole")
        
        with Cluster("VPC (10.0.0.0/16)\ndemo-vpc"):
            
            igw = InternetGateway("Internet\nGateway")
            
            rtb = RouteTable("Route Table\n0.0.0.0/0 -> IGW")
            
            with Cluster("Public Subnet (10.0.1.0/24)\nus-west-2a"):
                
                with Cluster("Security Group\nPort 3000 Ingress"):
                    
                    with Cluster("ECS Cluster: demo-cluster"):
                        
                        ecs_service = ElasticContainerServiceService("ECS Service\nDesired: 1\nLaunch: FARGATE")
                        
                        ecs_task = ElasticContainerServiceTask("Task Definition\nCPU: 256\nMemory: 512")
                        
                        container = ElasticContainerServiceContainer("Container\ndemo-container\nNode.js App\nPort 3000")
    
    # External to VPC
    users >> Edge(label="HTTP:3000") >> igw
    
    # VPC routing
    igw >> Edge(label="attached to VPC") >> rtb
    rtb >> Edge(label="routes to subnet") >> ecs_service
    
    # ECS hierarchy
    ecs_service >> Edge(label="runs") >> ecs_task
    ecs_task >> Edge(label="defines") >> container
    
    # Supporting services
    ecr >> Edge(label="image pull") >> container
    container >> Edge(label="log stream") >> logs
    iam >> Edge(label="execution permissions") >> ecs_task
