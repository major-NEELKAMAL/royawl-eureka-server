FROM eclipse-temurin:21-jdk-noble

# Default values if not provided during docker run
ENV SERVER_PORT=8761
ENV SPRING_PROFILES_ACTIVE=prod
# Heap is sized from the container --memory limit set in the Jenkinsfile
ENV MALLOC_ARENA_MAX=2
ENV JAVA_OPTS="-Djava.library.path=/usr/lib/jni:/usr/lib/x86_64-linux-gnu -XX:MaxRAMPercentage=50 -XX:G1PeriodicGCInterval=60000 -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=30 -XX:+ExitOnOutOfMemoryError -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/data/royawl/logs -Duser.timezone=Asia/Kolkata"

COPY target/*.jar royawl-eureka-server.jar

# Dynamically assign Port and Profile at runtime
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -Dlog4j2.configurationFile=${LOG4J2_CONFIG} -jar /royawl-eureka-server.jar --spring.profiles.active=${SPRING_PROFILES_ACTIVE} --server.port=${SERVER_PORT}"]