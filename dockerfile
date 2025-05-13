FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app

COPY . /app

RUN mvn clean package -DskipTests

FROM openjdk:17-jdk-slim

WORKDIR /app

COPY --from=build /app/target/hello-world-0.0.1.jar /app/hello-world.jar


EXPOSE 8080

ENTRYPOINT ["java", "-jar", "hello-world.jar"]
