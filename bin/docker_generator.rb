require 'json'
require 'fileutils'

# Define the main class
class DockerAppGenerator
  attr_reader :config_file, :config

  def initialize(config_file)
    @config_file = config_file
    load_config
  end

  # Load the configuration from the JSON file
  def load_config
    unless File.exist?(config_file)
      raise "Config file not found: #{config_file}"
    end

    @config = JSON.parse(File.read(config_file))
  end

  # Validate required fields in the configuration
  def validate_config
    required_keys = %w[RUBY_APPLICATION_DIRECTORY RUBY_APPLICATION_NAME PORT]
    missing_keys = required_keys.reject { |key| config.key?(key) }

    raise "Missing configuration keys: #{missing_keys.join(', ')}" unless missing_keys.empty?
  end

  # Generate Dockerfile for the application
  def generate_dockerfile
    app_directory = config['RUBY_APPLICATION_DIRECTORY']
    FileUtils.mkdir_p(app_directory) unless Dir.exist?(app_directory)

    dockerfile_content = <<~DOCKERFILE
      FROM ruby:3.2
      WORKDIR /app
      COPY . /app
      RUN bundle install
      CMD ["ruby", "app.rb"]
    DOCKERFILE

    File.write(File.join(app_directory, 'Dockerfile'), dockerfile_content)
    puts "Dockerfile generated in #{app_directory}"
  end

  # Build and push the Docker image
    # Authenticate with DockerHub
  def authenticate_dockerhub
    username = ENV['DOCKERHUB_USERNAME']
    password = ENV['DOCKERHUB_PASSWORD']

    if username.nil? || password.nil?
      raise "DockerHub credentials not found in environment variables. Set DOCKERHUB_USERNAME and DOCKERHUB_PASSWORD."
    end

    # Log in to DockerHub
    login_command = "echo #{password} | docker login --username #{username} --password-stdin"
    unless system(login_command)
      raise "DockerHub login failed. Check your credentials."
    end

    puts "Authenticated with DockerHub as #{username}"
  end

  # Build and push the Docker image
  def build_and_push_image
    authenticate_dockerhub

    app_name = config['RUBY_APPLICATION_NAME']
    app_directory = config['RUBY_APPLICATION_DIRECTORY']
    image_tag = "#{app_name}/#{app_name}:latest"

    # Build the Docker image
    system("docker build -t #{image_tag} #{app_directory}")

    # Push the Docker image to DockerHub
    system("docker push #{image_tag}")

    puts "Docker image #{image_tag} built and pushed to DockerHub"
  end

  # Generate docker-compose.yaml
  def generate_docker_compose
    app_name = config['RUBY_APPLICATION_NAME']
    port = config['PORT']
    compose_content = <<~YAML
      version: "3"
      services:
        #{app_name}:
          image: #{app_name}/#{app_name}:latest
          ports:
            - "#{port}:#{port}"
          volumes:
            - data:/data
            - /var/run/docker.sock:/var/run/docker.sock
          restart: unless-stopped
      volumes:
        data:
    YAML

    File.write('docker-compose.yaml', compose_content)
    puts 'docker-compose.yaml file generated'
  end

  # Execute the entire process
  def run
    validate_config
    generate_dockerfile
    build_and_push_image
    generate_docker_compose
    puts 'All tasks completed successfully'
  end
end

# Run the script
if ARGV.size != 1
  puts 'Usage: ruby generate_docker.rb <config.json>'
  exit 1
end

config_file = ARGV[0]

begin
  generator = DockerAppGenerator.new(config_file)
  generator.run
rescue StandardError => e
  puts "Error: #{e.message}"
end

=begin
example config file
{
  "RUBY_APPLICATION_DIRECTORY": "./my_ruby_app",
  "RUBY_APPLICATION_NAME": "my_ruby_app",
  "PORT": 3000
}
=end
