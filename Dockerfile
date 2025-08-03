# === STAGE 1: Build Tomcat Native ===
#FROM eclipse-temurin:21-jdk AS builder

#ARG TC_NATIVE_VERSION=2.0.9

# Cài gói cần thiết
#RUN apt-get update && apt-get install -y \
#    build-essential \
#    libapr1-dev \
#    libssl-dev \
#    curl \
#    tar \
#    ca-certificates \
#    && rm -rf /var/lib/apt/lists/*

# Tải và giải nén Tomcat Native
#WORKDIR /usr/local/src
#RUN curl -LO https://downloads.apache.org/tomcat/tomcat-connectors/native/${TC_NATIVE_VERSION}/source/tomcat-native-${TC_NATIVE_VERSION}-src.tar.gz \
#    && tar -xzf tomcat-native-${TC_NATIVE_VERSION}.tar.gz

# Biên dịch với OpenSSL
#WORKDIR /usr/local/src/tomcat-native-${TC_NATIVE_VERSION}/native
#RUN ./configure --with-apr=/usr/bin/apr-1-config --with-ssl=/usr --prefix=/usr/local/apr \
#    && make && make install

# Kiểm tra output (DEBUG - optional)
#RUN find /usr/local/apr -name 'libtcnative-1.so'

# === STAGE 2: Final Image ===
FROM eclipse-temurin:21-jdk

ENV CATALINA_HOME /opt/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
ENV TOMCAT_VERSION 10.1.43
# Set UTF-8
ENV LANG C.UTF-8
# Set timezone to Asia/Ho_Chi_Minh
ENV TZ Asia/Ho_Chi_Minh

# Tạo thư mục APR
#RUN mkdir -p /usr/local/apr/lib

# Copy thư viện native đã build
#COPY --from=builder /usr/local/apr/lib/libtcnative-1.so /usr/local/apr/lib/

# Cài Tomcat Native (libtcnative-1)
RUN apt-get update && \
    apt-get install -y libtcnative-1 && \
    ln -s /usr/lib/x86_64-linux-gnu/libtcnative-1.so /usr/lib/libtcnative-1.so
    
# Cài curl + tạo user
RUN apt-get update && apt-get install -y curl && \
    groupadd -r tomcat && useradd -r -g tomcat -d $CATALINA_HOME tomcat

# Copy WAR đã build sẵn
COPY build/libs/app.war $CATALINA_HOME/webapps/dongnt.war

# Copy custom catalina.properties into Tomcat conf/
COPY catalina.properties $CATALINA_HOME/conf/catalina.properties

# Thiết lập biến môi trường để Tomcat nhận native lib
ENV LD_LIBRARY_PATH=/usr/local/apr/lib

RUN mkdir -p $CATALINA_HOME
RUN curl -fsSL https://downloads.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz \
    | tar -xz -C $CATALINA_HOME --strip-components=1

# Copy keystore file
COPY certs/keystore.p12 $CATALINA_HOME/conf/keystore.p12

# Chmod và quyền sở hữu
#RUN chown -R tomcat:tomcat $CATALINA_HOME && chmod +x $CATALINA_HOME/bin/*.sh

#USER tomcat

WORKDIR $CATALINA_HOME

# Đổi port HTTP từ 8080 sang 8088
RUN sed -i 's/port="8080"/port="8088"/' $CATALINA_HOME/conf/server.xml

# Insert Connector with SSLHostConfig into server.xml
RUN sed -i '/<\/Service>/i \
<Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol" \n\
           SSLEnabled="true" maxThreads="150" scheme="https" secure="true"> \n\
  <SSLHostConfig> \n\
    <Certificate certificateKeystoreFile="conf/keystore.p12" \n\
                 certificateKeystorePassword="changeit" \n\
                 certificateKeystoreType="PKCS12" \n\
                 type="RSA" /> \n\
  </SSLHostConfig> \n\
</Connector>' $CATALINA_HOME/conf/server.xml

# Đảm bảo Listener APR tồn tại
RUN grep -q "AprLifecycleListener" $CATALINA_HOME/conf/server.xml || \
    sed -i '/<Server port="8005"/a <Listener className="org.apache.catalina.core.AprLifecycleListener"/>' $CATALINA_HOME/conf/server.xml

    # Thêm user admin vào tomcat-users.xml
RUN sed -i '/<\/tomcat-users>/i \
<role rolename="manager-gui"/>\n\
<role rolename="admin-gui"/>\n\
<user username="admin" password="admin" roles="manager-gui,admin-gui"/>' \
    $CATALINA_HOME/conf/tomcat-users.xml

# Cho phép truy cập manager từ mọi IP
RUN sed -i 's/className="org.apache.catalina.valves.RemoteAddrValve".*/className="org.apache.catalina.valves.RemoteAddrValve" allow=".*" \/>/' \
    $CATALINA_HOME/webapps/manager/META-INF/context.xml || true \
 && sed -i 's/className="org.apache.catalina.valves.RemoteAddrValve".*/className="org.apache.catalina.valves.RemoteAddrValve" allow=".*" \/>/' \
    $CATALINA_HOME/webapps/host-manager/META-INF/context.xml || true

EXPOSE 8088 8443

# Thiết lập quyền sở hữu cho thư mục Tomcat
#RUN chown -R tomcat:tomcat $CATALINA_HOME/*

# Chạy Tomcat
CMD ["catalina.sh", "run"]

