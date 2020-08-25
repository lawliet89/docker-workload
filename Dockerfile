FROM python:3.8.5-buster

ARG SPARK_JARS=jars
ARG IMG_PATH=kubernetes/dockerfiles
ARG SPARK_VERSION=3.0.0
ARG HADOOP_VERSION=3.2

ENV SPARK_HOME /opt/spark
ENV JAVA_HOME /usr/lib/jvm/adoptopenjdk-11-hotspot-amd64
ENV PYTHONPATH ${SPARK_HOME}/python/lib/pyspark.zip:${SPARK_HOME}/python/lib/py4j-*.zip
ENV PATH ${PATH}:${SPARK_HOME}/bin

WORKDIR /

RUN \
    # Add AdoptOpenJDK repository for Java 11
    apt-get update && \
    wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - && \
    apt-get install -y software-properties-common && \
    add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ && \
    # Install dependencies
    apt-get update && \
    apt-get install -y adoptopenjdk-11-hotspot python3-dev && \
    # Install Spark
    curl https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -OLJ && \
    tar -xzvf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    cd spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} && \
    mkdir -p ${SPARK_HOME}/python && \
    set -ex && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/work-dir && \
    touch /opt/spark/RELEASE && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    cp -r ${SPARK_JARS} /opt/spark/jars && \
    cp -r bin /opt/spark/bin && \
    cp -r sbin /opt/spark/sbin && \
    cp -r ${IMG_PATH}/spark/entrypoint.sh /opt/ && \
    cp -r examples /opt/spark/examples && \
    cp -r data /opt/spark/data && \
    cp -r python/lib ${SPARK_HOME}/python/lib && \
    # Sed command to remove use of tini
    sed -i -e 's/\/usr\/bin\/tini[^"]*//g' /opt/entrypoint.sh && \
    # Remove extracted Spark
    rm -rf /spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}

RUN \
    cd ${SPARK_HOME}/jars && \
    # Install GCS connector
    curl https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-hadoop3-latest.jar -OLJ && \
    # Install Hadoop AWS integration
    curl https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.1/hadoop-aws-3.2.1.jar -OLJ && \
    # Update Guava
    curl https://repo1.maven.org/maven2/com/google/guava/guava/29.0-jre/guava-29.0-jre.jar -OLJ && \
    rm /opt/spark/jars/guava-14.0.1.jar && \
    # Install AWS SDK For Java
    curl https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.848/aws-java-sdk-bundle-1.11.848.jar -OLJ

WORKDIR /opt/spark/work-dir

ENTRYPOINT [ "/opt/entrypoint.sh" ]
