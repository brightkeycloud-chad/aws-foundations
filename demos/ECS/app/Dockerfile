# Use the official Node.js 22 Alpine image for smaller size and better security
FROM node:22-alpine

# Set metadata labels
LABEL maintainer="AWS Demo Team"
LABEL description="Interactive Node.js demo for AWS ECS Fargate"
LABEL version="1.0.0"

# Create a non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy package files first for better Docker layer caching
COPY package*.json ./

# Install dependencies
RUN npm ci --omit=dev && \
    npm cache clean --force

# Copy application code
COPY index.js ./

# Create public directory for static files (if needed in future)
RUN mkdir -p public && chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the application
CMD ["node", "index.js"]
