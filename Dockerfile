FROM mcristinagrosu/bigstepinc_java_8

RUN apk add --update alpine-sdk

# Install Spark 1.6.2
RUN cd /opt && wget http://d3kbcqa49mib13.cloudfront.net/spark-1.6.2-bin-hadoop2.6.tgz
RUN tar xzvf /opt/spark-1.6.2-bin-hadoop2.6.tgz
RUN rm  /opt/spark-1.6.2-bin-hadoop2.6.tgz

# Spark pointers
ENV SPARK_HOME /opt/spark-1.6.2-bin-hadoop2.6
ENV R_LIBS_USER $SPARK_HOME/R/lib
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.8.2.1-src.zip
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Dlog4j.logLevel=info

RUN mv spark-1.6.2-bin-hadoop2.6 /opt/

ADD entrypoint.sh /opt/entrypoint.sh
RUN chmod 777 /opt/entrypoint.sh
ADD spark-defaults.conf /opt/spark-1.6.2-bin-hadoop2.6/conf/spark-defaults.conf.template
ADD spark-env.sh /opt/spark-1.6.2-bin-hadoop2.6/conf/spark-env.sh
ADD core-site.xml.template /opt/spark-1.6.2-bin-hadoop2.6/conf/core-site.xml.template

ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

# Install Miniconda3
RUN cd /opt && \
    mkdir -p $CONDA_DIR && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-3.9.1-Linux-x86_64.sh && \
    echo "6c6b44acdd0bc4229377ee10d52c8ac6160c336d9cdd669db7371aa9344e1ac3 *Miniconda3-3.9.1-Linux-x86_64.sh" | sha256sum -c - && \
    /bin/bash Miniconda3-3.9.1-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-3.9.1-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --yes conda==3.14.1

# Install Jupyter notebook 
RUN $CONDA_DIR/bin/conda install --yes \
    'notebook' \
    terminado \
    && $CONDA_DIR/bin/conda clean -yt

#Install Scala Spark kernel
ENV SBT_VERSION 0.13.11
ENV SBT_HOME /usr/local/sbt
ENV PATH ${PATH}:${SBT_HOME}/bin

# Install sbt
RUN curl -sL "http://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz" | gunzip | tar -x -C /usr/local && \
    echo -ne "- with sbt $SBT_VERSION\n" >> /root/.built

RUN cd /tmp && \
    curl -sL "http://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz" | gunzip | tar -x -C /usr/local && \
    echo -ne "- with sbt $SBT_VERSION\n" >> /root/.built &&\
    git clone https://github.com/apache/incubator-toree.git && \
    cd incubator-toree && \
    git checkout 846292233c && \
    make dist SHELL=/bin/bash && \
    mv dist/toree-kernel /opt/toree-kernel && \
    chmod +x /opt/toree-kernel && \
    rm -rf /tmp/incubator-toree 
    
#Install Python3 packages
RUN $CONDA_DIR/bin/conda install --yes \
    'ipywidgets' \
    'pandas' \
    'matplotlib' \
    'scipy' \
    'seaborn' \
    'scikit-learn' 
    
RUN $CONDA_DIR/bin/conda clean -yt

#Install Python2 packages
RUN $CONDA_DIR/bin/conda create -p $CONDA_DIR/envs/python2 python=2.7 \
    'ipython' \
    'ipywidgets' \
    'pandas' \
    'matplotlib' \
    'scipy' \
    'seaborn' \
    'scikit-learn' \
    && $CONDA_DIR/bin/conda clean -yt

RUN $CONDA_DIR/bin/conda config --add channels r
RUN $CONDA_DIR/bin/conda install --yes \
    'r' \
    'r-essentials' \
    'r-base' \
    'r-irkernel' \
    'r-ggplot2' \
    'r-rcurl' 
    
RUN $CONDA_DIR/bin/conda clean -yt
    
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
        
#        SparkMaster  SparkMasterWebUI  SparkWorkerWebUI REST     Jupyter Spark
EXPOSE    7077        8080              8081              6066    8888      4040

ENTRYPOINT ["/opt/entrypoint.sh"]
