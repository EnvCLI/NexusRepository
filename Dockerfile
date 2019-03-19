############################################################
# Build Image
############################################################

FROM maven:3-jdk-8-alpine AS build
ENV NEXUS_VERSION=3.15.2 \
    NEXUS_BUILD=01

RUN mkdir -p /nexus-repository-composer &&\
    printenv &&\
    cd /nexus-repository-composer &&\
    apk add git curl ca-certificates &&\
    git clone http://github.com/sonatype-nexus-community/nexus-repository-composer.git /nexus-repository-composer &&\
    sed -i "s/3.13.0-01/${NEXUS_VERSION}-${NEXUS_BUILD}/g" pom.xml &&\
    mvn clean package

############################################################
# Dockerfile
############################################################

# Base Image
FROM docker.io/sonatype/nexus3:3.15.2

############################################################
# Environment
############################################################
ENV NEXUS_VERSION=3.15.2 \
    NEXUS_BUILD=01

############################################################
# Installation
############################################################

# Become Root
USER root

# Install Plugins
RUN echo "Installing Composer Plugin" &&\
    sed -i 's@nexus-repository-maven</feature>@nexus-repository-maven</feature>\n        <feature prerequisite="false" dependency="false" version="0.0.2">nexus-repository-composer</feature>@g' /opt/sonatype/nexus/system/org/sonatype/nexus/assemblies/nexus-core-feature/${NEXUS_VERSION}-${NEXUS_BUILD}/nexus-core-feature-${NEXUS_VERSION}-${NEXUS_BUILD}-features.xml &&\
    sed -i 's@<feature name="nexus-repository-maven"@<feature name="nexus-repository-composer" description="org.sonatype.nexus.plugins:nexus-repository-composer" version="0.0.2">\n        <details>org.sonatype.nexus.plugins:nexus-repository-composer</details>\n        <bundle>mvn:org.sonatype.nexus.plugins/nexus-repository-composer/0.0.2</bundle>\n    </feature>\n    <feature name="nexus-repository-maven"@g' /opt/sonatype/nexus/system/org/sonatype/nexus/assemblies/nexus-core-feature/${NEXUS_VERSION}-${NEXUS_BUILD}/nexus-core-feature-${NEXUS_VERSION}-${NEXUS_BUILD}-features.xml

# Copy Artifacts
COPY --from=build /nexus-repository-composer/target/nexus-repository-composer-0.0.2.jar /opt/sonatype/nexus/system/org/sonatype/nexus/plugins/nexus-repository-composer/0.0.2/

############################################################
# Execution
############################################################

# User
USER nexus
