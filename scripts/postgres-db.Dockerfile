# sha256:7ad98329d513dd497293b951c195ca354274a77f12ddbbbbf85e68a811823d72 = postgres:17.9
FROM postgres@sha256:7ad98329d513dd497293b951c195ca354274a77f12ddbbbbf85e68a811823d72
COPY dbdata/*.sql /docker-entrypoint-initdb.d
EXPOSE 5432

ENV POSTGRES_USER=fruits \
		POSTGRES_PASSWORD=fruits \
		POSTGRES_DB=fruits