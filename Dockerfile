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

#        SparkMaster  SparkMasterWebUI  SparkWorkerWebUI REST
EXPOSE    7077        8080              8081              6066

ENTRYPOINT ["/opt/entrypoint.sh"]
