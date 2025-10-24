FROM ubuntu:20.04

# Set non-interactive frontend for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
        cowsay \
        fortunes \
        netcat-openbsd \
        bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the application script
COPY wisecow.sh /usr/local/bin/wisecow.sh

# Make the script executable
RUN chmod +x /usr/local/bin/wisecow.sh

# Create a non-root user and use a writable directory
RUN useradd -r -u 1001 -U appuser
USER 1001

# Use a writable working directory
WORKDIR /tmp

# Expose the service port
EXPOSE 4499

# Start the application
CMD ["/usr/local/bin/wisecow.sh"]
