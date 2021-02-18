# to-do-app
Install docker in Jenkins cointeiner 

curl -o docker-ce-cli.deb https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64/docker-ce-cli_19.03.8~3-0~debian-stretch_amd64.deb && \
    dpkg -i docker-ce-cli.deb && \
    rm docker-ce-cli.deb
  
or create Dockerfile
FROM jenkins/jenkins:lts

# Switch to root as the base image switch to jenkins user
USER root

# Download docker-cli and install it
RUN curl -o docker-ce-cli.deb https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64/docker-ce-cli_19.03.8~3-0~debian-stretch_amd64.deb && \
    dpkg -i docker-ce-cli.deb && \
    rm docker-ce-cli.deb

# Switch back to jenkins user
USER jenkins


#SonarQube

docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 sonarqube
