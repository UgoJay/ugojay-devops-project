# Stage 1: Build the Java application using Maven
FROM maven:3.8.8-eclipse-temurin-8 AS builder
WORKDIR /app
COPY . .
RUN mvn clean package

# Stage 2: Deploy the compiled WAR file to Tomcat
FROM tomcat:8.5.40-jre8-alpine
WORKDIR /usr/local/tomcat/webapps
RUN rm -rf *
COPY --from=builder /app/target/sampleapp.war ./ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]

