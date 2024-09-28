FROM --platform=${TARGETPLATFORM} debian:latest 

RUN apt update && apt install -y \
    curl \
    wget \
    openssh-client \
    build-essential \
    libssl-dev \
    openssh-server \
    apt-transport-https \
    ca-certificates \
    wget \
    dirmngr \
    gnupg \
    sudo \
    software-properties-common

# Install OpenJDK 8
ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:8 $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Set Hadoop environment variables
ENV HADOOP_VERSION=3.4.0

# Select mirror or original source for apache download
ENV APACHE_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/apache

ENV HADOOP_URL=${APACHE_MIRROR}/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz

# Set Hadoop environment variables
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_OPTS=-Djava.library.path=${HADOOP_HOME}/lib/native
ENV PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"


# Download and install Hadoop based on platform architecture
RUN wget -qO- ${HADOOP_URL} | tar -xz -C /opt/ && \
    mv /opt/hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    mkdir -p /usr/local/hadoop/logs

# Overwrite default HADOOP configuration files with our config files
COPY conf $HADOOP_HOME/etc/hadoop/

# Formatting HDFS
RUN mkdir -p /data/dfs/data /data/dfs/name /data/dfs/namesecondary && \
    hdfs namenode -format
VOLUME /data

# Helper script for starting YARN
ADD start-yarn.sh /usr/local/bin/start-yarn.sh

# Add Hadoop User and Group
RUN groupadd -r hadoop && \
    useradd -r -g hadoop -m -s /bin/bash hadoop

RUN echo 'hadoop:hadoop' | chpasswd

RUN echo 'hadoop ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN chown -R hadoop:hadoop ${HADOOP_HOME} && \
    chown -R hadoop:hadoop /usr/local/hadoop/logs && \
    chown -R hadoop:hadoop /data

# Configure SSH
RUN echo "Host *\n\tStrictHostKeyChecking no\n\n" > $HOME/.ssh/config
COPY ssh/id_ed25519 /tmp/id_ed25519
COPY ssh/id_ed25519.pub /tmp/id_ed25519.pub

USER hadoop
ENV HOME /home/hadoop

RUN echo 'export JAVA_HOME=${JAVA_HOME}' >> $HOME/.bashrc && \
    echo 'export HADOOP_HOME=${HADOOP_HOME}' >> $HOME/.bashrc && \
    echo 'export HADOOP_OPTS=${HADOOP_OPTS}' >> $HOME/.bashrc && \
    echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> $HOME/.bashrc

RUN mkdir -p $HOME/.ssh && \
    chmod 700 $HOME/.ssh

RUN cat /tmp/id_ed25519 > $HOME/.ssh/id_ed25519 && \
    cat /tmp/id_ed25519.pub > $HOME/.ssh/id_ed25519.pub

RUN cat $HOME/.ssh/id_ed25519.pub >> $HOME/.ssh/authorized_keys && \
    chmod 600 $HOME/.ssh/authorized_keys && \
    chmod 600 $HOME/.ssh/id_ed25519 && \
    chmod 644 $HOME/.ssh/id_ed25519.pub


####################
# Zookeeper
####################
USER root

ENV ZOOKEEPER_VERSION=3.9.2
ENV ZOOKEEPER_URL=${APACHE_MIRROR}/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz
ENV ZOOKEEPER_HOME=/opt/zookeeper
ENV PATH="$PATH:$ZOOKEEPER_HOME/bin"

# Download and install Zookeeper
RUN wget -qO- ${ZOOKEEPER_URL} | tar -xz -C /opt/ && \
    mv /opt/apache-zookeeper-${ZOOKEEPER_VERSION}-bin $ZOOKEEPER_HOME

# Overwrite default Zookeeper configuration files with our config files
COPY conf/zoo.cfg $ZOOKEEPER_HOME/conf/zoo.cfg

RUN mkdir -p /data/zookeeper

RUN chown -R hadoop:hadoop ${ZOOKEEPER_HOME} && \
    chown -R hadoop:hadoop /data/zookeeper

# Export Zookeeper environment variables
USER hadoop

RUN echo 'export ZOOKEEPER_HOME=${ZOOKEEPER_HOME}' >> $HOME/.bashrc && \
    echo 'export PATH=$PATH:$ZOOKEEPER_HOME/bin' >> $HOME/.bashrc


####################
# HBase
####################
USER root

ENV HBASE_VERSION=2.6.0
ENV HBASE_URL=${APACHE_MIRROR}/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-hadoop3-bin.tar.gz
ENV HBASE_HOME=/opt/hbase
ENV PATH="$PATH:$HBASE_HOME/bin"

# Download and install HBase
RUN wget -qO- ${HBASE_URL} | tar -xz -C /opt/ && \
    mv /opt/hbase-${HBASE_VERSION}-hadoop3 $HBASE_HOME

# Overwrite default HBase configuration files with our config files
COPY conf/hbase-site.xml $HBASE_HOME/conf/hbase-site.xml
COPY conf/regionservers $HBASE_HOME/conf/regionservers

RUN mkdir -p /data/hbase/zookeeper

RUN chown -R hadoop:hadoop ${HBASE_HOME} && \
    chown -R hadoop:hadoop /data/hbase/zookeeper

# Export HBase environment variables
USER hadoop

RUN echo 'export HBASE_HOME=${HBASE_HOME}' >> $HOME/.bashrc && \
    echo 'export HBASE_CLASSPATH=$HBASE_HOME/conf' >> $HOME/.bashrc && \
    echo 'export PATH=$PATH:$HBASE_HOME/bin' >> $HOME/.bashrc && \ 
    echo 'export HBASE_MANAGES_ZK=true' >> $HOME/.bashrc

####################
# Common
####################
USER root
COPY command /command
RUN chmod +x /command/*
RUN chown -R hadoop:hadoop /command


####################
# PORTS
####################
#
# http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.0/bk_HDP_Reference_Guide/content/reference_chap2.html
# http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_ig_ports_cdh5.html
# http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/core-default.xml
# http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml

# HDFS: NameNode (NN):
#	 9820 = fs.defaultFS			(IPC / File system metadata operations)
#						(9000 is also frequently used alternatively)
#	 9871 = dfs.namenode.https-address	(HTTPS / Secure UI)
#	 9870 = dfs.namenode.https-address	(HTTPS / Secure UI)
# HDFS: DataNode (DN):
#	9866 = dfs.datanode.address		(Data transfer)
#	9867 = dfs.datanode.ipc.address	(IPC / metadata operations)
#	9864 = dfs.datanode.https.address	(HTTPS / Secure UI)
# HDFS: Secondary NameNode (SNN)
#	9868 = dfs.secondary.http.address	(HTTP / Checkpoint for NameNode metadata)
# HBase: Master
#	9832 = hbase.master.port (WEB UI)
EXPOSE 9000 9870 9866 9867 9864 9868 8088 9832

USER hadoop
CMD ["hdfs"]