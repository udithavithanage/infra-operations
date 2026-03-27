# Installation Instructions

## Prerequisites
- Ensure you have the following software installed before proceeding:
  - [Node.js](https://nodejs.org/en/download/)
  - [Docker](https://docs.docker.com/get-docker/)
  - [Kubernetes](https://kubernetes.io/docs/setup/)
  - [Git](https://git-scm.com/downloads)

## Installation Methods

### Method 1: Local Development
1. Clone the repository:
   ```bash
   git clone https://github.com/tharindut-wso2/infra-operations.git
   cd infra-operations
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the application:
   ```bash
   npm start
   ```

### Method 2: Docker
1. Build the Docker image:
   ```bash
   docker build -t infra-operations .
   ```
2. Run the Docker container:
   ```bash
   docker run -p 8080:8080 infra-operations
   ```
3. Access the application at `http://localhost:8080`

### Method 3: Kubernetes
1. Deploy to your Kubernetes cluster:
   ```bash
   kubectl apply -f k8s/deployment.yaml
   ```
2. Make sure to set the correct service type in your deployment file.
3. Access the application via the Kubernetes service.

## Post-Installation Configuration
- Configure your environment variables as necessary.
- Ensure proper permissions for your application folders.

## Testing Verification
1. After installation, run the following command to ensure the application is working:
   ```bash
   curl http://localhost:8080/health
   ```
   You should receive a 200 OK response.

## Troubleshooting
- If you encounter issues during installation, please check:
  - Docker Daemon is running
  - Kubernetes context is set correctly
  - Dependencies are installed correctly

## Next Steps
- Refer to the [Documentation](https://github.com/tharindut-wso2/infra-operations/docs) for further usage instructions.
- Join our community forums for help and discussions.