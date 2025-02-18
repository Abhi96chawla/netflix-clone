# Use Node image for building the app
FROM node:16.17.0-buster as builder

# Set the working directory
WORKDIR /app

# Copy package.json and yarn.lock for dependency installation
COPY ./package.json ./yarn.lock ./

# Set yarn registry mirror to avoid timeouts and increase timeout duration
RUN yarn config set registry https://registry.npmmirror.com \
    && yarn config set network-timeout 600000 \
    && yarn install --frozen-lockfile

# Copy the rest of the application code
COPY . .

# Pass the TMDB API key as a build argument
ARG TMDB_V3_API_KEY="725a8e624fd702f2db22b07f3befa800"

# Set environment variables for Vite
ENV VITE_APP_TMDB_V3_API_KEY=${TMDB_V3_API_KEY}
ENV VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3"

# Build the project
RUN yarn build

# Use a minimal Nginx image for serving the built app
FROM nginx:stable-alpine

# Set the working directory for Nginx
WORKDIR /usr/share/nginx/html

# Remove the default Nginx HTML files
RUN rm -rf ./*

# Copy the built files from the Node builder stage
COPY --from=builder /app/dist .

# Expose port 80 for incoming traffic
EXPOSE 80

# Start Nginx in the foreground
ENTRYPOINT ["nginx", "-g", "daemon off;"]
