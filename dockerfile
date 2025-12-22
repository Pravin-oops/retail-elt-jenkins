# Start with the official Jenkins image
FROM jenkins/jenkins:lts

# Switch to root to install packages
USER root

# Install Python3 and Pip
RUN apt-get update && apt-get install -y python3 python3-pip python3-venv

# Create a virtual environment to avoid "externally managed environment" error
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install the Faker library inside the venv
RUN pip install faker

# Switch back to the Jenkins user for security
USER jenkins