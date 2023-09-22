# Use a minimal and trusted base image
FROM python:3.8
# Set non-root user to run the application
RUN groupadd -r myapp && useradd -r -g myapp myapp
# Create and set the working directory
WORKDIR /app
# Copy ncessary files
COPY . .
# Install application dependencies
RUN pip install -r requirements.txt
# Drop privileges for the application process
USER myapp
# Expose the application's port (change as needed)
EXPOSE 5000
CMD ["python","app.py"]
