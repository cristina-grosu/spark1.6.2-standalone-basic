FROM mcristinagrosu/bigstepinc_java_8

RUN apk add --update alpine-sdk

#RUN locale-gen en_US.UTF-8 && \
#    echo 'LANG="en_US.UTF-8"' > /etc/default/locale

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

# Install Miniconda2
RUN cd /opt && \
    mkdir -p $CONDA_DIR && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.1.11-Linux-x86_64.sh && \
    /bin/bash Miniconda3-4.1.11-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-4.1.11-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --yes conda

# Install Jupyter notebook 
RUN $CONDA_DIR/bin/conda install --yes \
    'notebook' \
    terminado \
    && $CONDA_DIR/bin/conda clean -yt

#Install Scala Spark kernel
RUN cd /tmp && \
    echo deb http://dl.bintray.com/sbt/debian / > /etc/apt/sources.list.d/sbt.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv 99E82A75642AC823 && \
    apt-get update && \
    git clone https://github.com/apache/incubator-toree.git && \
    apt-get install -yq --force-yes --no-install-recommends sbt && \
    cd incubator-toree && \
    git checkout 846292233c && \
    make dist SHELL=/bin/bash && \
    mv dist/toree-kernel /opt/toree-kernel && \
    chmod +x /opt/toree-kernel && \
    rm -rf ~/.ivy2 && \
    rm -rf ~/.sbt && \
    rm -rf /tmp/incubator-toree && \
    apt-get remove -y sbt && \
    apt-get clean
    
#Install Python3 packages
RUN $CONDA_DIR/bin/conda install --yes \
    'ipywidgets=4.0*' \
    'pandas=0.17*' \
    'matplotlib=1.4*' \
    'scipy=0.16*' \
    'seaborn=0.6*' \
    'scikit-learn=0.16*' \
    && $CONDA_DIR/bin/conda clean -yt

RUN $CONDA_DIR/bin/conda create -p $CONDA_DIR/envs/python2 python=2.7 \
    'ipython' \
    'ipywidgets' \
    'pandas' \
    'matplotlib' \
    'scipy' \
    'seaborn' \
    'scikit-learn' \
    && $CONDA_DIR/bin/conda clean -yt

RUN $CONDA_DIR/bin/conda create -p $CONDA_DIR/envs/R \
    'r-base' \
    'r-irkernel' \
    'r-ggplot2' \
    'r-rcurl' && $CONDA_DIR/bin/conda clean -yt
    
RUN mkdir -p /opt/conda/share/jupyter/kernels/scala
COPY kernel.json /opt/conda/share/jupyter/kernels/scala/

RUN bash -c '. activate python2 && \
    python -m ipykernel.kernelspec --prefix=$CONDA_DIR && \
    . deactivate'

RUN apk add jq

# Set PYSPARK_HOME in the python2 spec
RUN jq --arg v "$CONDA_DIR/envs/python2/bin/python" \
        '.["env"]["PYSPARK_PYTHON"]=$v' \
        $CONDA_DIR/share/jupyter/kernels/python2/kernel.json > /tmp/kernel.json && \
        mv /tmp/kernel.json $CONDA_DIR/share/jupyter/kernels/python2/kernel.json
   

#        SparkMaster  SparkMasterWebUI  SparkWorkerWebUI REST     Jupyter
EXPOSE    7077        8080              8081              6066    8888 

ENTRYPOINT ["/opt/entrypoint.sh"]
