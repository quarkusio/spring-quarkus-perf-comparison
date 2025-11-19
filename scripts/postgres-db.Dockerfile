FROM postgres:17
COPY dbdata/*.sql /docker-entrypoint-initdb.d
EXPOSE 5432

ENV POSTGRES_USER=fruits \
		POSTGRES_PASSWORD=fruits \
		POSTGRES_DB=fruits