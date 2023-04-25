#!/bin/bash

# Check if Java is installed
if ! [ -x "$(command -v java)" ]; then
  echo "Java is not installed. Please install Java and try again."
  exit 1
fi

# Check if ZooKeeper is already installed
if [ -d "/opt/zookeeper" ]; then
  echo "ZooKeeper is already installed."
else
  # Download and extract ZooKeeper
  wget https://downloads.apache.org/zookeeper/zookeeper-3.7.0/apache-zookeeper-3.7.0-bin.tar.gz -P /tmp/
  tar -xzf /tmp/apache-zookeeper-3.7.0-bin.tar.gz -C /opt/
  mv /opt/apache-zookeeper-3.7.0-bin /opt/zookeeper

  # Configure ZooKeeper
  cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg

  # Start ZooKeeper
  /opt/zookeeper/bin/zkServer.sh start
fi

# Check if Kafka is already installed
if [ -d "/opt/kafka" ]; then
  echo "Kafka is already installed."

  # Check if Kafka is running
  kafka_pid=$( ps aux | grep kafka.Kafka | grep -v grep | awk '{print $2}' )

  if [ -n "$kafka_pid" ]; then
    echo "Kafka is running with PID $kafka_pid."
  else
    echo "Kafka is installed but not running. Starting Kafka..."

    # Start Kafka
    /opt/kafka_2.13-3.0.0/bin/kafka-server-start.sh -daemon /opt/kafka_2.13-3.0.0/config/server.properties

    echo "Kafka started successfully."
  fi
else
  # Download and extract Kafka
  wget https://downloads.apache.org/kafka/3.0.0/kafka_2.13-3.0.0.tgz -P /tmp/
  tar -xzf /tmp/kafka_2.13-3.0.0.tgz -C /opt/

  # Configure Kafka
  sed -i 's/broker.id=0/broker.id=1/g' /opt/kafka_2.13-3.0.0/config/server.properties
  sed -i 's/#listeners=PLAINTEXT:\/\/:9092/listeners=PLAINTEXT:\/\/localhost:9092/g' /opt/kafka_2.13-3.0.0/config/server.properties
  sed -i 's/#advertised.listeners=PLAINTEXT:\/\/your.host.name:9092/advertised.listeners=PLAINTEXT:\/\/localhost:9092/g' /opt/kafka_2.13-3.0.0/config/server.properties

  # Start
  Kafka /opt/kafka_2.13-3.0.0/bin/kafka-server-start.sh -daemon /opt/kafka_2.13-3.0.0/config/server.properties

  echo "Kafka installation completed successfully."
fi
