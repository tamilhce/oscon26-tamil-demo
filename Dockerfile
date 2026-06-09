FROM opensearchproject/opensearch:3.6.0

# Copy and install ICU analysis plugin
COPY plugins/analysis-icu-3.6.0.zip /tmp/
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch file:///tmp/analysis-icu-3.6.0.zip

# Copy and install Tamil analysis plugin
COPY plugins/analysis-tamil-3.6.0.zip /tmp/
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch file:///tmp/analysis-tamil-3.6.0.zip

# Clean up
RUN rm -f /tmp/*.zip
