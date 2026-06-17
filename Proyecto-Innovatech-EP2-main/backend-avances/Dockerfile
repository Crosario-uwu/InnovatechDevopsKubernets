# Etapa 1: compilación del backend Spring Boot
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace

# Primero se copian dependencias para aprovechar caché de Docker
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY src ./src
RUN mvn -B clean package -DskipTests

# Etapa 2: ejecución con usuario no root
FROM eclipse-temurin:21-jre-jammy AS runtime
WORKDIR /app

RUN groupadd -r appuser && useradd -r -g appuser appuser
COPY --from=build /workspace/target/*.jar /app/app.jar
RUN chown -R appuser:appuser /app

USER appuser
EXPOSE 8081

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
