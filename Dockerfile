# Pokéventure game server + the vendored Pokémon Showdown engine.
# Build from the repository root: docker build -t pokeventure-server .
# The vendor/pokemon-showdown submodule must be checked out first.

FROM node:22-bookworm-slim AS engine
WORKDIR /app

# olm/native deps are not needed by the simulator, but Showdown's install
# script wants git available while it resolves its own packages.
RUN apt-get update \
  && apt-get install -y --no-install-recommends git ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY vendor/pokemon-showdown/package.json vendor/pokemon-showdown/package-lock.json ./vendor/pokemon-showdown/
WORKDIR /app/vendor/pokemon-showdown
RUN npm ci --no-audit --no-fund

COPY vendor/pokemon-showdown ./
RUN node build

FROM node:22-bookworm-slim AS runtime
ENV NODE_ENV=production
WORKDIR /app

COPY --from=engine /app/vendor ./vendor

COPY server/package.json server/package-lock.json ./server/
WORKDIR /app/server
RUN npm ci --no-audit --no-fund

COPY server ./

EXPOSE 8787
# The server reads PORT (Render/Fly inject their own); 8787 is the default.
CMD ["npm", "start"]
