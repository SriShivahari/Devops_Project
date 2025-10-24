Zero-Cost CI/CD: A Practical DevOps Pipeline for a Flask NLP API on AWS
1. Architecture Overview & Free Tier Strategy
This report provides a comprehensive, step-by-step plan for implementing a fully automated Continuous Integration and Continuous Deployment (CI/CD) pipeline for a Flask-based Natural Language Processing (NLP) API. The entire architecture is designed to be deployed exclusively on AWS services that are eligible for the AWS Free Tier, ensuring a zero-cost implementation for new accounts within their first 12 months. The plan prioritizes simplicity, security, and automation, making it ideal for developers new to DevOps and the AWS ecosystem.

1.1. High-Level Architecture Diagram
The architecture is designed around a single, multi-purpose Amazon EC2 instance to maximize the use of free tier resources. This instance serves as the CI/CD server, the Docker host, and the application server.

The CI/CD workflow is as follows:

Code Commit: A developer pushes a code change to a GitHub repository.

Webhook Trigger: A configured GitHub webhook sends a notification to the Jenkins server.

CI Server (Jenkins on EC2): The Jenkins server, running on a free-tier EC2 instance, receives the webhook and automatically starts a new build job.

Build: Jenkins checks out the latest source code from GitHub. It then uses Docker to build a new container image based on the Dockerfile in the repository.

Push to Registry: Upon a successful build, Jenkins pushes the newly created Docker image to a private repository in Amazon Elastic Container Registry (ECR).

Deploy: Jenkins executes a deployment script on the same EC2 instance. This script pulls the new image from ECR, stops the currently running application container, and starts a new container from the updated image.

Monitoring: The EC2 instance is configured with the Amazon CloudWatch Agent, which continuously sends system-level metrics (CPU, memory, disk) and application logs to Amazon CloudWatch for monitoring and alerting.

User Access: The end-user can access the live Flask NLP API via the public IP address and designated port of the EC2 instance.

1.2. Narrative Walkthrough of the CI/CD Flow
Imagine a developer needs to update the NLP model or change an API response message. The process begins when they commit their changes to the main branch of their Git repository and push it to GitHub. This single git push command sets off a fully automated chain of events.

Instantly, GitHub sends a secure notification to a unique URL corresponding to the Jenkins server. Jenkins, which has been listening for this signal, immediately initiates the predefined pipeline. The first stage involves cloning the repository to ensure it has the latest code.

Next, the pipeline enters the build stage. Jenkins invokes the Docker daemon running on the same machine, instructing it to build a new container image. This process reads the Dockerfile, installs all Python dependencies (like Flask, PyTorch, or TensorFlow), and packages the application code into a self-contained, portable image. This image is tagged with a unique identifier, such as the build number, to distinguish it from previous versions.

Once the image is built, the pipeline proceeds to the push stage. Jenkins authenticates with Amazon ECR using permissions granted by an IAM role attached to the EC2 instance—a secure process that avoids storing any secret keys on the server. It then uploads the new Docker image to the designated ECR repository.

The final stage is deployment. Jenkins executes a series of shell commands on the EC2 instance. It first pulls the new image from ECR. It then gracefully stops and removes the old application container. Finally, it starts a new container from the newly downloaded image, exposing the Flask application on its designated port (e.g., 5000). The entire deployment process results in only a few seconds of downtime.

Throughout this entire sequence, the CloudWatch agent is collecting data in the background. If the new deployment causes a spike in CPU usage or memory consumption, these metrics will be visible on a CloudWatch dashboard, and pre-configured alarms can notify the developer of potential issues. The developer can then verify the change by simply calling the public API endpoint and observing the updated behavior.

1.3. Table: AWS Free Tier Service Allotments
Operating within the free tier is the central constraint of this project. The following table summarizes the specific limits of the services used in this plan. Adherence to these limits is critical to avoid incurring costs.   

Service	Free Tier Type	Monthly Allotment	Key Consideration for this Project
Amazon EC2	12 Months Free	750 hours of t2.micro or t3.micro instance usage	
Sufficient to run one instance continuously. We will host Jenkins, Docker, and the app on this single instance.

Amazon EBS	12 Months Free	30 GB of General Purpose (SSD) storage	
Ample for the OS, Jenkins, Docker images, and application data. The default 8 GB is sufficient, but 30 GB is the limit.

Amazon ECR	12 Months Free	500 MB of private repository storage	
This is the most critical constraint. NLP Docker images can be large. Image optimization and cleanup are mandatory.

Amazon CloudWatch	Always Free	5 GB Log Ingestion, 10 Custom Metrics, 10 Alarms	
Sufficient for basic monitoring of our single EC2 instance's health (CPU, Memory, Disk).

Data Transfer	Always Free	100 GB/month data transfer out to the internet	
Generous for a small API. Data transfer between ECR and EC2 in the same region is free, which is a key architectural choice.

  
The most significant challenge presented by these limits is the 500 MB storage cap for private Amazon ECR repositories. NLP applications often depend on large libraries and models, which can result in Docker images that easily exceed this limit after just one or two builds. Each pipeline run generates a new image, and without a deliberate strategy for management, this limit will be quickly breached, leading to unexpected costs. Therefore, this plan incorporates two crucial mitigation strategies:   

Multi-stage Dockerfiles: A technique to build the application in an intermediate container with all the build tools and then copy only the necessary artifacts to a smaller, final production image. This can drastically reduce image size.

Image Cleanup: A manual or scripted process to periodically remove old, unused images from the ECR repository to reclaim space.

These practices are not just technical optimizations; they are essential financial disciplines for operating effectively in the cloud.

2. Phase 1: Foundational AWS Security and Environment Setup
Before provisioning any infrastructure, a secure and cost-aware foundation must be established. This phase focuses on creating the necessary permissions using AWS Identity and Access Management (IAM) and setting up billing alerts to prevent accidental charges.

2.1. Creating a Secure IAM Role for the Jenkins Server
Instead of creating an IAM user and embedding long-lived access keys on the EC2 instance—a significant security risk—the AWS best practice is to use an IAM Role. The EC2 instance will "assume" this role, granting it temporary, automatically rotated credentials to interact with other AWS services. This is the most secure method for granting permissions to applications running on EC2.

The Jenkins software and other tools on the instance, such as the AWS CLI and the CloudWatch Agent, will automatically use these role-based credentials without any manual configuration. This approach adheres to the principle of least privilege by granting only the specific permissions required for the pipeline to function.

Step-by-Step IAM Role Creation:

Navigate to the IAM service in the AWS Management Console.

Select Roles from the left-hand navigation pane and click Create role.

For Trusted entity type, select AWS service.

For Use case, select EC2 and click Next.

On the Add permissions page, search for and attach the following two AWS-managed policies:

AmazonEC2ContainerRegistryPowerUser: This policy grants the necessary permissions to push and pull images from Amazon ECR.

CloudWatchAgentServerPolicy: This policy allows the EC2 instance to send metrics and logs to CloudWatch.   

Click Next.

On the Name, review, and create page, enter a descriptive Role name, such as Jenkins-EC2-Role.

Review the selected policies and click Create role.

This role is now ready to be attached to the EC2 instance during the launch process.

2.2. Configuring AWS Billing and Free Tier Alerts
To ensure there are no surprise charges, it is essential to configure proactive billing alerts. This creates a safety net that provides peace of mind while experimenting and learning.

1. Enable Free Tier Usage Alerts:

AWS can automatically send an email notification when your usage of a service is approaching its free tier limit.

Navigate to the Billing & Cost Management dashboard in the AWS console.

In the left navigation pane, under Preferences, select Billing preferences.

Under Alert preferences, click Edit.

Check the box for Receive AWS Free Tier alerts.

Enter the email address where you want to receive notifications and click Update. You will now be notified when your usage exceeds 85% of the free tier limit for any service.   

2. Create a Zero-Spend Budget:

A budget provides an additional layer of protection by alerting you if your account starts to incur any charges, even if they are not related to free-tier services.

In the Billing & Cost Management dashboard, select Budgets from the left navigation pane.

Click Create budget.

Select Use a template (simplified) and choose the Zero spend budget.

Enter an Email recipient for the alert.

Click Create budget.

This budget will now monitor your account and send a notification if your actual or forecasted spending exceeds $0.01, effectively catching any unintended costs immediately.   

3. Phase 2: Provisioning and Configuring the CI/CD Server
With the security and billing foundation in place, the next step is to launch and configure the single EC2 instance that will host the entire CI/CD environment.

3.1. Launching the Free Tier EC2 Instance
The following steps detail the precise configuration required to launch an EC2 instance that is compliant with the AWS Free Tier.

Navigate to the EC2 service in the AWS Management Console and click Launch instance.

Name: Provide a descriptive name, such as Jenkins-Server.

Application and OS Images (AMI): Select Amazon Linux, and ensure the chosen AMI is Amazon Linux 2023 AMI. It should be marked "Free tier eligible".   

Instance type: Select t2.micro. This is the primary free-tier eligible instance type. In some regions, t3.micro may also be available under the free tier.   

Key pair (login): Create a new key pair. Give it a name (e.g., jenkins-key), select RSA for the type and .pem for the file format. Download the key pair and store it in a secure location on your local machine. You will need this file to connect to the instance via SSH.   

Network settings: Click Edit.

VPC and Subnet: Leave the default settings.

Security group: Select Create a new security group. Give it a name like jenkins-sg.

Inbound security groups rules: Configure the following rules to allow necessary traffic:

Rule 1 (SSH):

Type: SSH

Source type: My IP (This restricts administrative access to your current public IP address for better security).

Rule 2 (Jenkins):

Type: Custom TCP

Port range: 8080

Source type: Anywhere (0.0.0.0/0) (This allows you to access the Jenkins web UI from any location).

Rule 3 (Flask App):

Type: Custom TCP

Port range: 5000 (Or the port your Flask app uses).

Source type: Anywhere (0.0.0.0/0) (This makes your final API publicly accessible).

Configure storage: Ensure the size of the root volume is 30 GB or less to stay within the free tier limit. The default of 8 GB is sufficient for this project.   

Advanced details: Expand this section.

IAM instance profile: Select the Jenkins-EC2-Role created in the previous phase. This step is critical for granting the instance the necessary permissions.

Scroll down to the User data field at the bottom. This is where the automated setup script will be placed.

3.2. Automating Server Setup with a User Data Script
Instead of manually connecting to the instance and running dozens of installation commands, we can automate the entire server setup using a User Data script. This script runs automatically the first time the instance boots, installing and configuring all required software. This approach makes the server setup repeatable, predictable, and less prone to human error. If the server ever needs to be rebuilt, one can simply terminate the old instance and launch a new one with the same script, creating a fresh, perfectly configured environment in minutes.   

Copy and paste the following script into the User data field in the EC2 launch wizard:

Bash
#!/bin/bash
# Update all system packages
sudo dnf update -y

# Install Git, Docker, and Java (required for Jenkins)
sudo dnf install git docker java-17-amazon-corretto -y

# Start and enable the Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add the default ec2-user to the docker group to run docker commands without sudo
sudo usermod -aG docker ec2-user

# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install jenkins -y

# Start and enable the Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Add the jenkins user to the docker group so Jenkins can execute Docker commands
sudo usermod -aG docker jenkins

# Install the AWS CloudWatch Agent
sudo yum install amazon-cloudwatch-agent -y
After pasting the script, review all settings and click Launch instance.

3.3. Finalizing Jenkins and CloudWatch Configuration
After a few minutes, the instance will be running, and the user data script will have completed. A few final manual steps are required to complete the setup.

1. Connect to the EC2 Instance:

Find the Public IPv4 address of your instance from the EC2 dashboard.

Open a terminal on your local machine, navigate to where you saved your .pem key file, and connect using SSH. First, set the correct permissions for the key file:

Bash
chmod 400 your-key-name.pem
Then connect to the instance (replace the IP address and key name):

Bash
ssh -i "your-key-name.pem" ec2-user@<your-ec2-public-ip>
2. Configure Jenkins:

Unlock Jenkins: Open a web browser and navigate to http://<your-ec2-public-ip>:8080. You will be prompted for an initial administrator password. Retrieve it by running the following command in your SSH terminal :   

Bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
Copy the output and paste it into the Jenkins setup page.

Install Plugins: On the next screen, select Install suggested plugins. This will install a standard set of useful plugins. After the installation, we will add a few more.

Create Admin User: Create your first admin user account and password.

Instance Configuration: Confirm the Jenkins URL and save. You should now be at the Jenkins dashboard.

Install Additional Plugins:

Navigate to Manage Jenkins > Plugins.

Go to the Available plugins tab.

Search for and install the following plugins:

Amazon ECR (Provides integration for ECR credential handling).   

Docker Pipeline (Provides syntax for using Docker in Jenkinsfiles).   

Ensure the GitHub Integration plugin was installed with the suggested set. If not, install it as well.   

Restart Jenkins if prompted.

3. Configure the CloudWatch Agent:

The agent is installed, but it needs a configuration file to know which metrics to collect.

In your SSH session, create a configuration file:

Bash
sudo nano /opt/aws/amazon-cloudwatch-agent/bin/config.json
Paste the following JSON content into the file. This configuration tells the agent to collect memory and disk usage percentage every 60 seconds, which are not collected by default.   

JSON
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    },
    "metrics_collected": {
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
Save the file (press Ctrl+X, then Y, then Enter).

Start the CloudWatch agent with this new configuration:

Bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
The server is now fully configured and ready for pipeline creation.

4. Phase 3: Building the Automated Deployment Pipeline
This phase focuses on creating the artifacts and automation scripts that define the CI/CD pipeline, connecting the source code repository to the live deployment environment.

4.1. Preparing the Flask Application for Containerization
The application code needs two key additions: a Dockerfile to define how it's packaged into a container, and an ECR repository to store the resulting image.

1. Creating an Optimized Dockerfile:

A multi-stage build is used to create the smallest possible final image, which is crucial for staying within the 500 MB ECR free tier limit. The first stage, named builder, uses a full Python image to compile dependencies. The second, final stage uses a lightweight "slim" image and copies only the application code and the installed dependencies from the builder stage, discarding all the build tools and intermediate files.

Create a file named Dockerfile in the root of your Flask application's Git repository with the following content:

Dockerfile
# Stage 1: The builder stage
# This stage installs dependencies into a virtual environment.
FROM python:3.9-slim-buster AS builder

# Set the working directory
WORKDIR /usr/src/app

# Set environment variables to prevent writing.pyc files and to buffer output
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install pipenv or just use pip with requirements.txt
# For this example, we use requirements.txt
COPY requirements.txt.
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: The final production stage
# This stage copies the installed dependencies and application code.
FROM python:3.9-slim-buster

# Set the working directory
WORKDIR /usr/src/app

# Copy the virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy the application source code
COPY..

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Set the new path to include the virtual environment's binaries
ENV PATH="/opt/venv/bin:$PATH"

# Define the command to run the application
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
(Note: This example assumes your main Flask application file is app.py and the Flask app instance is named app. Adjust the CMD as needed. It also uses gunicorn as a production-ready web server.)

2. Creating the Amazon ECR Repository:

Navigate to the Elastic Container Registry (ECR) service in the AWS console.

Click Create repository.

Set Visibility to Private.

Enter a Repository name (e.g., flask-nlp-api).

Leave all other settings at their defaults and click Create repository.

Once created, select the repository and copy the URI. You will need this for the Jenkinsfile.

4.2. Crafting the Jenkinsfile: The Heart of Automation
The Jenkinsfile is a text file that defines the entire CI/CD pipeline as code. It lives in the root of the source code repository, meaning the pipeline definition is version-controlled along with the application itself. This is a core principle of modern DevOps known as "Pipeline-as-Code."

Create a file named Jenkinsfile in the root of your repository with the following declarative pipeline script. Replace the placeholder values in the environment block with your specific details.

Groovy
pipeline {
    agent any

    environment {
        // Replace with your ECR Repository URI details from the AWS console
        AWS_ACCOUNT_ID = 'YOUR_AWS_ACCOUNT_ID'
        AWS_REGION = 'us-east-1' // Change to your AWS region
        ECR_REPOSITORY = 'flask-nlp-api' // The name of your ECR repository
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "build-${env.BUILD_NUMBER}"
        APP_CONTAINER_NAME = 'flask-nlp-app'
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                echo 'Checking out code from GitHub...'
                git branch: 'main', url: 'https://github.com/YOUR_USERNAME/YOUR_REPO.git'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                echo "Building Docker image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                
                // The Amazon ECR plugin provides credentials via the IAM role.
                // The 'ecr:region:.' syntax tells the Docker Pipeline plugin to use
                // the ECR credential provider for the specified region.
                docker.withRegistry("https://${ECR_REGISTRY}", "ecr:${AWS_REGION}:.") {
                    def customImage = docker.build("${ECR_REPOSITORY}:${IMAGE_TAG}")
                    
                    // Push the image with the build number tag
                    customImage.push()
                    
                    // Also push the 'latest' tag for convenience
                    customImage.push('latest')
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo "Deploying container ${APP_CONTAINER_NAME}..."
                
                // This script runs on the Jenkins server, which is also the deployment target.
                // It uses the AWS CLI (authenticated by the IAM role) to get a Docker login token.
                sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    
                    echo "Pulling latest image from ECR..."
                    docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    
                    echo "Stopping and removing old container if it exists..."
                    if; then
                        docker stop ${APP_CONTAINER_NAME}
                        docker rm ${APP_CONTAINER_NAME}
                    fi
                    
                    echo "Starting new container..."
                    docker run -d --name ${APP_CONTAINER_NAME} -p 5000:5000 ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                '''
            }
        }
    }
}
This pipeline is designed for simplicity and efficiency. Because Jenkins and Docker are running on the same EC2 instance where the application will be deployed, the "Deploy" stage can directly execute docker commands. There is no need for complex deployment tools, SSH connections, or separate authentication, making the process transparent and easy for a beginner to understand.   

4.3. Integrating Jenkins with GitHub
The final step is to create the pipeline job in Jenkins and connect it to the GitHub repository via a webhook.

1. Creating the Pipeline Job in Jenkins:

On the Jenkins dashboard, click New Item.

Enter an item name (e.g., flask-nlp-api-pipeline), select Pipeline, and click OK.

On the configuration page, scroll down to the Pipeline section.

Change the Definition to Pipeline script from SCM.

For SCM, select Git.

For Repository URL, enter the HTTPS URL of your GitHub repository (e.g., https://github.com/your-username/your-repo.git).

The Branch Specifier should default to */main or */master. Ensure this matches your repository's default branch.

Click Save.

2. Setting up the GitHub Webhook:

This will enable GitHub to automatically trigger the Jenkins pipeline every time you push a new commit.   

In your GitHub repository, go to Settings > Webhooks.

Click Add webhook.

For Payload URL, enter your Jenkins server URL followed by /github-webhook/. It must be a publicly accessible URL.

Example: http://<your-ec2-public-ip>:8080/github-webhook/

For Content type, select application/json.

Leave the Secret field blank for this simple setup.

Under Which events would you like to trigger this webhook?, select Just the push event.

Ensure the Active checkbox is checked and click Add webhook.

GitHub will immediately send a test "ping" event to Jenkins. You should see a green checkmark next to the webhook, indicating a successful delivery.

5. Phase 4: Monitoring, Validation, and Demonstration
With the pipeline built, the final phase is to monitor the system's health, validate that the automation works as expected, and conduct a full end-to-end demonstration.

5.1. Implementing System Monitoring with CloudWatch
The CloudWatch agent configured earlier is now sending detailed metrics from the EC2 instance. These can be visualized on a dashboard for at-a-glance monitoring.

1. Creating a CloudWatch Dashboard:

Navigate to the CloudWatch service in the AWS console.

In the left navigation pane, select Dashboards and click Create dashboard.

Give the dashboard a name (e.g., Jenkins-Server-Health) and click Create dashboard.

You will be prompted to add your first widget. Select Line chart and click Configure.

Under Metrics, you can now add data points to the graph.

To add CPU Utilization: Select EC2 > Per-Instance Metrics, find your Jenkins-Server instance, and select the CPUUtilization metric.

To add Memory Usage: Select CWAgent > InstanceId, find your instance ID, and select the mem_used_percent metric.

To add Disk Usage: Select CWAgent > InstanceId, path, find your instance with the / path, and select disk_used_percent.

Click Create widget. You can add more widgets for network traffic (NetworkIn, NetworkOut) or other metrics. A dashboard provides a consolidated view of the server's health, transforming monitoring from a reactive task to a proactive one.   

2. Setting up CloudWatch Alarms:

Alarms automatically notify you when a metric crosses a defined threshold, allowing you to respond to potential problems before they become critical.

In the CloudWatch console, select Alarms > All alarms and click Create alarm.

Click Select metric. Navigate to the CPUUtilization metric for your EC2 instance as you did for the dashboard.

Under Conditions, set the threshold. For example:

Threshold type: Static

Whenever CPUUtilization is...: Greater

than...: 70 (for 70 percent)

Configure the alarm to trigger if this condition is met for 1 out of 1 consecutive period(s) of 5 Minutes.

Click Next. For Notification, you can create a new SNS (Simple Notification Service) topic to send an email alert. The SNS free tier includes 1,000 email notifications per month.

Give the alarm a name (e.g., High-CPU-Jenkins-Server) and click Create alarm.

5.2. The Final Live Demo: A Verification Plan
This checklist provides a structured plan to demonstrate that every component of the pipeline is functioning correctly.

Establish the Initial State:

Open the Jenkins dashboard in one browser tab. It should show the flask-nlp-api-pipeline job with no builds running.

In your SSH terminal, run docker ps. Note the CONTAINER ID and UP time of the running flask-nlp-app container.

In another browser tab or using a tool like curl, access your API endpoint (e.g., http://<your-ec2-public-ip>:5000/) and observe the initial response.

Introduce a Code Change:

On your local machine, open the main Flask application file (e.g., app.py).

Make a small, easily identifiable change. For example, modify the text in a JSON response from "message": "API is live" to "message": "API updated via CI/CD".

Save the file.

Trigger the Automated Pipeline:

Commit and push the change to your GitHub repository:

Bash
git add.
git commit -m "Demonstrating live CI/CD update"
git push origin main
Observe the Automation in Action:

Switch to the Jenkins dashboard. Within seconds, you should see a new build for your pipeline automatically start and progress through the stages: Checkout, Build & Push, and Deploy.

(Optional) In your GitHub repository's webhook settings, you can see a new delivery log with a 200 OK response, confirming the trigger was successful.

Verify the New Deployment:

Once the Jenkins pipeline successfully completes, return to your SSH terminal and run docker ps again.

Observe that the CONTAINER ID is different and the UP time has reset to "a few seconds ago," confirming the old container was replaced.

In the AWS ECR console, refresh your repository view. You will see a new image pushed with both the new build tag (e.g., build-2) and the latest tag.

Confirm the Live Application Change:

Return to the browser tab with your API endpoint and refresh the page (or re-run the curl command).

You should now see the updated response: "message": "API updated via CI/CD".

This successful demonstration validates the end-to-end functionality of the entire automated pipeline.

6. Conclusion and Next Steps
6.1. Summary of Achievements
This report has detailed the complete process for building a secure, automated, and fully functional CI/CD pipeline on AWS using only free-tier services. The key achievements include:

A Zero-Cost Platform: A robust DevOps environment was constructed without incurring any cloud service fees by carefully adhering to AWS Free Tier limits.

End-to-End Automation: A pipeline was created that automatically builds, tests (implicitly), and deploys a containerized Flask application triggered by a simple git push.

Infrastructure as Code Principles: The use of an EC2 User Data script for server configuration and a Jenkinsfile for pipeline definition embeds infrastructure and process logic directly into version-controlled code.

Security Best Practices: The architecture was built on a secure foundation using IAM roles, eliminating the need for hard-coded credentials and adhering to the principle of least privilege.

Integrated Monitoring: The system includes proactive monitoring and alerting through Amazon CloudWatch, providing essential visibility into the server's health and performance.

6.2. Beyond the Free Tier: Recommendations for Growth
This single-server architecture is an excellent starting point for learning, personal projects, and proofs of concept. As an application grows in complexity and user traffic, the following evolutionary steps should be considered:

Separate Build and Application Hosts: In a production environment, the Jenkins server should run on a separate instance from the application servers. This prevents resource contention, where a resource-intensive build process could negatively impact the performance of the live application.

Managed AWS DevOps Services: Self-hosting Jenkins requires ongoing maintenance (updates, security patching, plugin management). For a more scalable and managed solution, consider migrating to AWS-native CI/CD services like AWS CodePipeline, AWS CodeBuild, and AWS CodeDeploy. These services integrate seamlessly and handle the underlying infrastructure for you.

Container Orchestration: To run the application with high availability and scalability, a container orchestrator is necessary. Amazon Elastic Container Service (ECS) is a powerful yet simpler orchestrator that is a natural next step from this project's setup. For more complex microservices architectures, Amazon Elastic Kubernetes Service (EKS) is the industry standard.   

Stateful Components: This project assumes a stateless API. A real-world application would require a database. Amazon RDS (Relational Database Service) offers managed databases (like PostgreSQL and MySQL) and also has a free tier that includes 750 hours per month of a db.t2.micro instance, making it a perfect addition to this architecture.