# use a smaller base image
FROM ruby:3.2-slim

# Set the working directory inside the container
WORKDIR /app

# Install dependencies for building gem (if required) and clean up afterwards
RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*

# Copy only the Gemfile and Gemfile.lock first for better caching
COPY Gemfile Gemfile.lock ./

# Install the necessary gems
RUN bundle install --without development test

# Copy the rest of the application code
COPY . .

# No EXPOSE AND CMD

