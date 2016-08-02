FROM mcristinagrosu/bigstepinc_java_8

# Install Spark 2.0.0
RUN cd /opt && wget http://d3kbcqa49mib13.cloudfront.net/spark-2.0.0-bin-hadoop2.7.tgz
RUN tar xzvf /opt/spark-2.0.0-bin-hadoop2.7.tgz
RUN rm  /opt/spark-2.0.0-bin-hadoop2.7.tgz

# Spark pointers
ENV SPARK_HOME /opt/spark-2.0.0-bin-hadoop2.7
ENV R_LIBS_USER $SPARK_HOME/R/lib
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.8.2.1-src.zip
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Dlog4j.logLevel=info

RUN mv spark-2.0.0-bin-hadoop2.7 /opt/

ADD entrypoint.sh /opt/entrypoint.sh
RUN chmod 777 /opt/entrypoint.sh
ADD spark-defaults.conf /opt/spark-2.0.0-bin-hadoop2.7/conf/spark-defaults.conf.template
ADD spark-env.sh /opt/spark-2.0.0-bin-hadoop2.7/conf/spark-env.sh

ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

RUN cd /opt && \
    mkdir -p $CONDA_DIR && \
    wget --quiet -y http://repo.continuum.io/archive/Anaconda2-4.1.1-Linux-x86_64.sh && \
    /bin/bash Anaconda2-4.1.1-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Anaconda2-4.1.1-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --yes conda

RUN $CONDA_DIR/bin/conda install --yes \
    'notebook' \
    terminado \
    && $CONDA_DIR/bin/conda clean -yt

#        SparkMaster  SparkMasterWebUI  SparkWorkerWebUI REST     Jupyter
EXPOSE    7077        8080              8081              6066    8888 

ENTRYPOINT ["/opt/entrypoint.sh"]
