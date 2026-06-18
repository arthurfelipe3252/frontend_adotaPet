# ── Stage 1: build do Flutter Web ─────────────────────────────────────────────
# Imagem com o Flutter SDK já instalado (cirruslabs). Versão fixada na que o
# projeto usa (3.41.4 / Dart 3.11). Se a tag não existir no registry, troque
# para `:stable`.
FROM ghcr.io/cirruslabs/flutter:3.41.4 AS build

WORKDIR /app

# Evita o aviso de "dubious ownership" do git dentro do container.
RUN git config --global --add safe.directory /app

# 1) Só os manifests primeiro → cacheia a camada de dependências.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# 2) Resto do código e build de produção.
COPY . .
RUN flutter build web --release \
    # Símbolos de debug do wasm (skwasm/canvaskit) não são usados em produção.
    && find build/web -name "*.symbols" -delete
# Para apontar a API por ambiente (opcional), o HttpClient precisaria ler
# String.fromEnvironment('API_BASE_URL'); aí o build viraria:
#   RUN flutter build web --release --dart-define=API_BASE_URL=https://...

# ── Stage 2: serve estático com nginx ─────────────────────────────────────────
FROM nginx:alpine-slim
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
