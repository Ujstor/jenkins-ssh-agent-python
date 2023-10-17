
<picture>
  <img class src="https://logos-download.com/wp-content/uploads/2016/10/Jenkins_logo_wordmark.png" width="600px">
</picture>

# Jenkins Custom Python SSH Agent

This repository contains code and scripts to set up a Jenkins environment for building and testing Python projects with custom SSH agent support. The included Dockerfile uses the `jenkins/ssh-agent` as the base image and installs various tools and dependencies needed for Python development and containerization.


## Setting up the Jenkins Environment

1. Start by creating a Jenkins Pipeline Job in your Jenkins environment.

2. In your Jenkins job configuration, specify the location of this repository for the job to retrieve the code.

3. Customize your job's build triggers and parameters to suit your project's requirements.

4. Configure your Docker Hub credentials in Jenkins (Credentials Manager) and specify the corresponding `dockerCredentialsId` in your Jenkinsfile.

5. Customize the environment variables in your Jenkinsfile to match your project:

   - `GITHUB_USER`: Your GitHub username or organization name.
   - `GITHUB_REPO`: Your GitHub repository name.
   - `DOCKER_HUB_USERNAME`: Your Docker Hub username.
   - `DOCKER_REPO_NAME`: The name of your Docker repository.
   - `VERSION_PART`: The part of the version to increment (Patch, Minor, Major).

6. Customize the Dockerfile to include any additional dependencies or tools your project may require.

## Usage

Once you have configured your Jenkins environment and set up your job, the pipeline will perform the following tasks:

1. Check out the code from your GitHub repository.
2. Run the pytest script to test your Python project.
3. If the branch being built is the `master` branch, generate a new Docker image tag based on the specified `VERSION_PART`.
4. Build a Docker image with the generated tag.
5. Log in to Docker Hub using your credentials.
6. Push the Docker image to your Docker Hub repository.
7. Clean up Docker images on the Jenkins environment.


# Setting up Jenkins SSH Agent

In a Jenkins environment, agents play a crucial role in distributing the workload and executing jobs in parallel. This guide will show you how to set up Jenkins agents using Docker images with SSH, allowing you to expand your build environment efficiently.


## Generating an SSH Key Pair

To set up an SSH key pair, follow these steps:

1. Open a terminal on a machine where you have access to execute commands. It could be the Jenkins controller, a host (if using containers), an agent's machine, or your developer machine.

2. Generate the SSH key pair by running the following command:

    ```bash
    ssh-keygen -f ~/.ssh/jenkins_agent_key
    ```

## Creating a Jenkins SSH Credential

1. Go to your Jenkins dashboard.

2. In the main menu, click on "Manage Jenkins" and select "Manage Credentials."

3. Click on the "Add Credentials" option from the global menu.

4. Fill in the following information:

   - Kind: SSH Username with private key
   - ID: jenkins
   - Description: The Jenkins SSH key
   - Username: jenkins
   - Private Key: Select "Enter directly" and paste the content of your private key file located at `~/.ssh/jenkins_agent_key`
   - Passphrase: Fill in your passphrase used to generate the SSH key pair (leave empty if you didn't use one)

## Creating Your Docker Agent

### On Linux

Use the `docker-ssh-agent` image to create the agent containers:

```bash
docker run -v /var/run/docker.sock:/var/run/docker.sock -d --rm --name=agent1 -p 22:22 \
    -e "JENKINS_AGENT_SSH_PUBKEY=[your-public-key]" \
    ujstor/jenkins-slave-python:0.0.10
```

Replace `[your-public-key]` with your own SSH public key. You can find your public key value by running `cat ~/.ssh/jenkins_agent_key.pub` on the machine where you created it.

If your machine already has an SSH server running on port 22, consider using a different port for the Docker command, such as `-p 4444:22`.

### On Windows

Use the `docker-ssh-agent` image to create the agent containers:

```bash
docker run -v /var/run/docker.sock:/var/run/docker.sock -d --rm --name=agent1 --network jenkins -p 22:22 `
    -e "JENKINS_AGENT_SSH_PUBKEY=[your-public-key]" `
    ujstor/jenkins-slave-python:0.0.10
```

Replace `[your-public-key]` with your own SSH public key. You can find your public key on Windows with the command: `Get-Content $Env:USERPROFILE\.ssh\jenkins_agent_key.pub`.

### Registering the Agent in Jenkins

1. Go to your Jenkins dashboard.

2. Click on "Manage Jenkins" in the main menu.

3. Select "Manage Nodes and Clouds."

4. Click on "New Node" from the side menu.

5. Fill in the Node/agent name and select the type (e.g., Name: agent1, Type: Permanent Agent).

6. Fill in the following fields:

   - Remote root directory (e.g., /home/jenkins)
   - Label (e.g., agent1)
   - Usage (e.g., only build jobs with label expression)
   - Launch method (e.g., Launch agents by SSH)
     - Host (e.g., localhost or your IP address)
     - Credentials (e.g., jenkins)
     - Host Key Verification Strategy (e.g., Manually trusted key verification)
     - Change port if needed; in my case i need use port 2222 
    <br/>
    <br/>

    ```bash
    docker run -v /var/run/docker.sock:/var/run/docker.sock -d --rm --name=agent1 -p 2222:22 \
    -e "JENKINS_AGENT_SSH_PUBKEY=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICW/o8iiXXXHmGVRVjPQbps+QWqqQ7fcq9BR0vAXwbg9 root@ubuntu-1" \
    ujstor/jenkins-slave-python:0.0.10
    ```

7. Click the "Save" button, and the agent1 will be registered but offline. Click on it to launch the agent.

8. You should see "This node is being launched." If not, click the "Relaunch agent" button and wait for it to become online.

## Delegating the First Job to Agent1

1. Go to your Jenkins dashboard.

2. Select "New Item" from the side menu.

3. Enter a name for your job (e.g., "First Job to Agent1").

4. Choose "Freestyle project" and click "OK."

5. Check the option "Restrict where this project can be run."

6. In the "Label" field, enter the agent1 label (e.g., "agent1").

7. Under the "Build" section, choose "Execute shell."

8. In the "Command" field of the "Execute shell" step, add the command: `echo $NODE_NAME`.

9. Save the job and click "Build Now."

10. Wait a few seconds, and then go to the "Console Output" page to see the job's output. You should receive output similar to the following:

    ```text
    Started by user Admin User
    Running as SYSTEM
    Building remotely on agent1 in workspace /home/jenkins/workspace/First Job to Agent1
    [First Job to Agent1] $ /bin/sh -xe /tmp/jenkins15623311211559049312.sh
    + echo $NODE_NAME
    agent1
    Finished: SUCCESS
    ```

Your Jenkins agent setup is now complete. If you encounter issues with the agent not starting via SSH, make sure to check the port configuration and adjust it accordingly in Jenkins.
