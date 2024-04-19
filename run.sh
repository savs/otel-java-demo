clear

# export JAVA_TOOL_OPTIONS="-javaagent:./opentelemetry-javaagent.jar" \
#   OTEL_TRACES_EXPORTER=logging \
#   OTEL_METRICS_EXPORTER=logging \
#   OTEL_LOGS_EXPORTER=logging \
#   OTEL_METRIC_EXPORT_INTERVAL=15000

export OTEL_SERVICE_NAME=demodice \
    OTEL_RESOURCE_ATTRIBUTES=deployment.environment=development,service.name=demodice,service.instance.id=98606 \
    OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 \
    OTEL_EXPORTER_OTLP_PROTOCOL=grpc \
    OTEL_TRACES_EXPORTER=otlp \
    OTEL_METRICS_EXPORTER=otlp \
    OTEL_LOGS_EXPORTER=otlp \
    OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED=true \
    OTEL_EXPORTER_OTLP_INSECURE=true \
    JAVA_TOOL_OPTIONS="-javaagent:./opentelemetry-javaagent.jar"


result=${PWD##*/}          # to assign to a variable
result=${result:-/}  

#echo $result
#gradle assemble
java -jar ./build/libs/$result.jar
