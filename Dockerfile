FROM ubuntu:22.04 as runner
ARG runner_version=2.309.0
ENV username=rasah
ENV HOME=/home/$username
ENV runner_home=$HOME/action-runner
ENV DEBIAN_FRONTEND=noninteractive
LABEL RunnerVersion=${runner_version}

RUN apt update  
RUN apt install -y curl jq hostname tar gzip
RUN useradd --user-group --system --create-home --no-log-init $username

RUN mkdir $runner_home && cd $runner_home \
  && curl -O -Ls https://github.com/actions/runner/releases/download/v${runner_version}/actions-runner-linux-x64-${runner_version}.tar.gz \
  && tar xzf ./actions-runner-linux-x64-${runner_version}.tar.gz \
  && chown -R $username:$username /home/$username

RUN $runner_home/bin/installdependencies.sh

COPY startup.sh startup.sh
RUN chmod +x startup.sh

USER $username
CMD ["./startup.sh"]


FROM runner as ghar
# project specific requirements

USER root

# Install dependencies for Dotnet Core 6.0
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  unzip \
  wget \
  gnupg \
  vim \
  && rm -rf /var/lib/apt/lists/*

# Install Google Chrome and ChromeDriver
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
  apt-get update && \
  apt-get install -y google-chrome-stable && \
  CHROMEDRIVER_VERSION=`curl -sS https://chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
  wget -q -O /tmp/chromedriver.zip https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip && \
  unzip /tmp/chromedriver.zip chromedriver -d /usr/local/bin/ && \
  rm /tmp/chromedriver.zip

# Install Docker dependencies
RUN apt-get update && apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Add Docker's official GPG key
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up Docker repository
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io openssl

RUN curl -so /tmp/sag.crt 'http://crl2.softwareag.com/Software%20AG%20Root%20CA%202020.crt' && \ 
  openssl x509 -inform DER -in /tmp/sag.crt -out /usr/local/share/ca-certificates/eur.ad.sag.crt && \ 
  update-ca-certificates

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
  chmod +x /usr/local/bin/docker-compose

# begin: Add new tools required for the project begins here
RUN apt install -y python3-pip && pip3 --version

# end: Add new tools required for the project ends here

USER $username
