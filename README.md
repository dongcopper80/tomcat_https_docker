# Build image:

docker build -t my-tomcat10-jdk21 .

# Chạy container:

docker run -d -p 8080:8080 --name tomcat10 my-tomcat10-jdk21

# Truy cập Tomcat tại:

http://localhost:8080

# Tạo file cert 

keytool -genkeypair \
  -alias tomcat \
  -keyalg RSA \
  -keysize 2048 \
  -keystore certs/keystore.p12 \
  -storeType PKCS12 \
  -validity 365 \
  -storepass changeit \
  -dname "CN=localhost, OU=Dev, O=Company, L=City, S=State, C=VN"

# build project

./gradlew --configure-on-demand -x check clean build

# run docker

docker-compose up --build

# Lenh xoa toan bo docker 

docker system prune -a --volumes