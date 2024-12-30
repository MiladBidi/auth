FROM nexus:8082/keycloak:23.0.3 as builder

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
# Configure postgres database vendor
ENV KC_DB=postgres

ENV KC_FEATURES="token-exchange,scripts,preview"

WORKDIR /opt/keycloak

# A example build step that downloads a JAR file from a URL and adds it to the providers directory
ADD --chown=keycloak:keycloak deployment/*  /opt/keycloak/providers/

RUN /opt/keycloak/bin/kc.sh build --cache=ispn

FROM nexus:8082/keycloak:23.0.3

COPY --from=builder /opt/keycloak/ /opt/keycloak/

# https://github.com/keycloak/keycloak/issues/19185#issuecomment-1480763024
USER root
RUN sed -i '/disabledAlgorithms/ s/ SHA1,//' /etc/crypto-policies/back-ends/java.config
USER keycloak

RUN /opt/keycloak/bin/kc.sh show-config

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

