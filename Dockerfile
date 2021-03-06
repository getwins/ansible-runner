ARG BASE_IMAGE=docker.io/fedora:32

FROM ${BASE_IMAGE}

ADD demo/project /runner/project
ADD demo/env /runner/env
ADD demo/inventory /runner/inventory

# UNDO Before 2.0 Release:
# Install Ansible and Runner
#ADD https://releases.ansible.com/ansible-runner/ansible-runner.el8.repo /etc/yum.repos.d/ansible-runner.repo
#RUN dnf install -y ansible-runner
RUN dnf install -y python3-pip rsync openssh-clients sshpass glibc-langpack-en git \
    https://github.com/krallin/tini/releases/download/v0.19.0/tini_0.19.0-amd64.rpm && \
    rm -rf /var/cache/dnf

RUN dnf install -y gcc python3-devel
RUN pip3 install bindep https://github.com/ansible/ansible/archive/devel.tar.gz \
    https://github.com/ansible/ansible-runner/archive/devel.tar.gz

RUN useradd runner && usermod -aG root runner

ADD utils/entrypoint.sh /bin/entrypoint
RUN chmod +x /bin/entrypoint

# In OpenShift, container will run as a random uid number and gid 0. Make sure things
# are writeable by the root group.
RUN for dir in \
      /home/runner \
      /home/runner/.ansible/tmp \
      /runner \
      /home/runner \
      /runner/env \
      /runner/inventory \
      /runner/project \
      /runner/artifacts ; \
    do mkdir -m 0775 -p $dir ; chmod g+rwx $dir ; chgrp root $dir ; done && \
    for file in \
      /home/runner/.ansible/galaxy_token \
      /etc/passwd ; \
    do touch $file ; chmod g+rw $file ; chgrp root $file ; done

VOLUME /runner

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV RUNNER_BASE_COMMAND=ansible-playbook
ENV HOME=/home/runner

WORKDIR /runner

ENTRYPOINT ["entrypoint"]
CMD ["ansible-runner", "run", "/runner"]
