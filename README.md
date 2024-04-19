# otel-java-demo

Simple demo of collecting telemetry with OpenTelemetry and sending to Grafana

Let's see how otel instruments java and create a demo.
Based on https://opentelemetry.io/docs/languages/java/getting-started/

# Prerequisites

* JDK `brew install openjdk`
* Gradle `brew install gradle`
* Grafana Alloy running and configured to collect opentelemetry and send it to Grafana Cloud

# Agent config

This should work (get values for endpoints fom Grafana Cloud):

	// Grafana Agent v0.40.0 is REQUIRED
	otelcol.receiver.otlp "default" {
	  // https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.receiver.otlp/

	  // configures the default grpc endpoint "0.0.0.0:4317"
	  grpc { }
	  // configures the default http/protobuf endpoint "0.0.0.0:4318"
	  http { }

	  output {
	    metrics = [otelcol.processor.resourcedetection.default.input]
	    logs    = [otelcol.processor.resourcedetection.default.input]
	    traces  = [otelcol.processor.resourcedetection.default.input]
	  }
	}

	otelcol.processor.resourcedetection "default" {
	  // https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.processor.resourcedetection/
	  detectors = ["env", "system"] // add "gcp", "ec2", "ecs", "elastic_beanstalk", "eks", "lambda", "azure", "aks", "consul", "heroku"  if you want to use cloud resource detection

	  system {
	    hostname_sources = ["os"]
	  }

	  output {
	    metrics = [otelcol.processor.transform.add_resource_attributes_as_metric_attributes.input]
	    logs    = [otelcol.processor.batch.default.input]
	    traces  = [
	      otelcol.processor.batch.default.input,
	      otelcol.connector.host_info.default.input,
	    ]
	  }
	}

	otelcol.connector.host_info "default" {
	  // https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.connector.host_info/
	  host_identifiers = ["host.name"]

	  output {
	    metrics = [otelcol.processor.batch.default.input]
	  }
	}

	otelcol.processor.transform "add_resource_attributes_as_metric_attributes" {
	  // https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.processor.transform/
	  error_mode = "ignore"

	  metric_statements {
	    context    = "datapoint"
	    statements = [
	      "set(attributes[\"deployment.environment\"], resource.attributes[\"deployment.environment\"])",
	      "set(attributes[\"service.version\"], resource.attributes[\"service.version\"])",
	    ]
	  }

	  output {
	    metrics = [otelcol.processor.batch.default.input]
	  }
	}

	otelcol.processor.batch "default" {
	  // https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.processor.batch/
	  output {
	    metrics = [otelcol.exporter.prometheus.grafana_cloud_prometheus.input]
	    logs    = [otelcol.exporter.loki.grafana_cloud_loki.input]
	    traces  = [otelcol.exporter.otlp.grafana_cloud_tempo.input]
	  }
	}

	otelcol.exporter.loki "grafana_cloud_loki" {
	  // https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.exporter.loki/
	  forward_to = [loki.write.grafana_cloud_loki.receiver]
	}

	otelcol.exporter.prometheus "grafana_cloud_prometheus" {
	  // https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.exporter.prometheus/
	  add_metric_suffixes = false
	  forward_to          = [prometheus.remote_write.grafana_cloud_prometheus.receiver]
	}

	prometheus.remote_write "grafana_cloud_prometheus" {
	  // https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.remote_write/
	  endpoint {
	    url = "https://YOUR_PROMETHEUS_ENDPOINT_HERE/api/prom/push"

	    basic_auth {
	      username = "YOUR_PROM_USERNAME"
	      password = "YOUR_TOKEN"
	    }
	  }
	}


	otelcol.exporter.otlp "grafana_cloud_tempo" {
	  // https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.exporter.otlp/
	  client {
	    endpoint = "YOUR_TEMPO_ENDPOINT:443"
	    auth     = otelcol.auth.basic.grafana_cloud_tempo.handler
	  }
	}

	otelcol.auth.basic "grafana_cloud_tempo" {
	  // https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.auth.basic/
	  username = "YOUR_TEMPO_USERNAME"
	  password = "YOUR_TEMPO_TOKEN"
	}  


# Build

    gradle assemble

# Run

Do this because gradle builds based on the current working directory name. Put the following in a script `run.sh`:

    clear
    result=${PWD##*/}          # to assign to a variable
    result=${result:-/}  
    java -jar ./build/libs/$result.jar

# Test with OTEL

    curl -L -O https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
    export JAVA_TOOL_OPTIONS="-javaagent:./opentelemetry-javaagent.jar" \
      OTEL_TRACES_EXPORTER=logging \
      OTEL_METRICS_EXPORTER=logging \
      OTEL_LOGS_EXPORTER=logging \
      OTEL_METRIC_EXPORT_INTERVAL=15000
    ./run.sh


# Send telemetry to Grafana Cloud

* Note here that localhost:4317 references Grafana Alloy. Check it's running: `lsof -i TCP:4317`
* Note that we need to reset the exporters (default is otlp, but we previously set to logging above)

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
    ./run.sh

# Create some load so we can see what's going on

	while true
	do
		clear
		curl http://localhost:8080/rolldice
		sleep 1
	done

