# Keycloak Setup with PostgreSQL in Docker

This guide details the setup and configuration of Keycloak with a PostgreSQL database using Docker Compose. Follow these steps to ensure a smooth deployment.

---

## Prerequisites

1. **Docker** and **Docker Compose** installed.
2. Basic knowledge of Docker networking and volumes.

---

## Directory Structure
Ensure your directory structure resembles the following:

```
/srv/docker/keycloak/
  |- compose.yml
  |- Dockerfile
  |- themes/ (optional for custom themes)
```

---

## Docker Compose Configuration

### **compose.yml**

```yaml

services:

  keycloak:
    container_name: keycloak
    image: mykeycloak:v1
    command: ['start', '--optimized']
    restart: always
    environment:
      JAVA_OPTS_APPEND: -Dkeycloak.profile.feature.upload_scripts=enabled
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: password
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      PROXY_ADDRESS_FORWARDING: "true"
      KC_HTTP_ENABLED: 'true'
      KC_HOSTNAME_STRICT_HTTPS: false
      KC_HOSTNAME_STRICT: false
      KC_HOSTNAME_STRICT_BACKCHANNEL: false
      KC_HOSTNAME_URL: https://tkeycloak.example.com/
      KC_PROXY: edge
      KC_BOOTSTRAP_ADMIN_USERNAME: admin
      KC_BOOTSTRAP_ADMIN_PASSWORD: admin
      KC_HOSTNAME_ADMIN_URL: https://tkeycloak.example.com/      
    ports:
      - "8180:8080"
      - "8787:8787" # debug port
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/opt/docker/keycloak/themes/:/opt/keycloak/themes/"
    networks:
      - mynet

  postgres:
    image: postgres:15
    container_name: postgres-keycloak
    environment:
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: password
      POSTGRES_DB: keycloak
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - mynet

volumes:
  postgres_data:

networks:
  mynet:
    name: mynet
    external: true
```

---

## Dockerfile for Custom Keycloak Image

### **Dockerfile**

```dockerfile
FROM quay.io/keycloak/keycloak:latest as builder

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure a database vendor
ENV KC_DB=postgres

WORKDIR /opt/keycloak

# Generate a development keystore (replace with proper certificates in production)
RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore conf/server.keystore
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:latest
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
```

Build the custom Keycloak image:
```bash
docker build -t mykeycloak:v1 .
```

---

## Deployment Steps

1. **Start Services:**
   ```bash
   docker-compose up -d
   ```

2. **Check Logs:**
   Monitor logs to ensure services start correctly:
   ```bash
   docker logs keycloak
   docker logs postgres-keycloak
   ```

3. **Verify Database Connectivity:**
   Enter the Keycloak container:
   ```bash
   docker exec -it keycloak bash
   ```

   Test database connectivity:
   ```bash
   apt-get update && apt-get install -y postgresql-client
   psql -h postgres -U keycloak -d keycloak
   ```

4. **Access Keycloak:**
   Open your browser and navigate to:
   ```
   http://<your-server-ip>:8180
   ```

   Default Admin Credentials:
   - Username: `admin`
   - Password: `admin`

---

## Troubleshooting

### **Common Errors:**

1. **`Failed to obtain JDBC connection`**
   - Verify the database credentials in `compose.yml`.
   - Ensure PostgreSQL is running and reachable.

2. **`Password authentication failed for user "keycloak"`**
   - Check PostgreSQL logs:
     ```bash
     docker logs postgres-keycloak
     ```
   - Reset the database user password:
     ```sql
     ALTER USER keycloak WITH PASSWORD 'your-new-pass';
     ```

3. **Cannot Access Keycloak Admin Console**
   - Ensure Keycloak is reachable at the correct port (default `8180`).
   - Confirm `KC_HOSTNAME_URL` is correctly configured.

---

## Customization Options

- **Themes:** Place custom themes in `/opt/docker/keycloak/themes/`.
- **Environment Variables:** Adjust Keycloak settings via environment variables in `compose.yml`.
- **Database Configuration:** Modify PostgreSQL credentials or database name as needed.

---

## References

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)

---

## License

This setup is open for use and customization. Ensure security configurations are implemented for production environments.

