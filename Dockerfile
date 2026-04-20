FROM mongo:8.0.20-noble

COPY init/01-blog-init.js /docker-entrypoint-initdb.d/
USER mongodb
