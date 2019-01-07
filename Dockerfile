# Stage 1: Build the website
FROM node:lts-alpine AS build

ARG PALANTIR_VERSION=0.3.1

# Install bins needed
RUN apk add --no-cache curl

RUN mkdir /app; \
  mkdir /app-src

WORKDIR /app

# Get the source and extract them
RUN curl -o /app/palantir.tar.gz -fSL "https://github.com/CodeCorico/palantir/archive/v${PALANTIR_VERSION}.tar.gz"; \
  tar zxvf palantir.tar.gz --strip-components=1; \
  rm palantir.tar.gz; \
  cp -R /app/* /app-src

# Install the deps & build the website
RUN npm ci; \
  npm run build

# Stage 2: Install the cli & server
FROM node:lts-alpine

ENV SERVER_PORT=80
ENV SERVER_STATICS=/palantir

RUN mkdir /app; \
  mkdir /palantir

WORKDIR /app

# Add the docker entrypoints
COPY ./docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
# Backwards compat
RUN ln -s usr/local/bin/docker-entrypoint.sh /

# Copy sources and dist from the build stage
COPY --from=build /app-src /app
COPY --from=build /app/dist /app/dist

# Install the production deps and install the cli as global
RUN npm i --production; \
  npm pack; \
  npm i -g palantir-*.tgz; \
  rm palantir-*.tgz

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["npm", "start"]
