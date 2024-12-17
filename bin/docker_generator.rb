require 'json'
require 'fileutils'

# Main class to handle Docker application generation
class DockerAppGenerator
  attr_reader :config_file, :config

  def initialize(config_file)
    @config_file = config_file
    load_config
  end

  # Load and parse the configuration JSON file
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

  # Authenticate with DockerHub, ensuring required credentials are set
  def authenticate_dockerhub
    # Validate environment variables using Array#reject
    required_env_vars = %w[DOCKERHUB_USERNAME DOCKERHUB_PASSWORD]
    missing_env_vars = required_env_vars.reject { |var| ENV[var] }

    raise "Missing DockerHub credentials: #{missing_env_vars.join(', ')}" unless missing_env_vars.empty?

    username = ENV['DOCKERHUB_USERNAME']
    password = ENV['DOCKERHUB_PASSWORD']

    # Log in to DockerHub
    login_command = "echo #{password} | docker login --username #{username} --password-stdin"
    unless system(login_command)
      raise "DockerHub login failed. Check your credentials."
    end

    puts "Authenticated with DockerHub as #{username}"
  end

  # Generate a Dockerfile in the application directory
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
  def build_and_push_image
    authenticate_dockerhub

    app_name = config['RUBY_APPLICATION_NAME']
    app_directory = config['RUBY_APPLICATION_DIRECTORY']
    image_tag = "#{app_name}/#{app_name}:latest"

    # Build the Docker image
    unless system("docker build -t #{image_tag} #{app_directory}")
      raise "Failed to build Docker image: #{image_tag}"
    end

    # Push the Docker image to DockerHub
    unless system("docker push #{image_tag}")
      raise "Failed to push Docker image: #{image_tag}"
    end

    puts "Docker image #{image_tag} built and pushed to DockerHub"
  end

  # Generate a docker-compose.yaml file
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
    puts "docker-compose.yaml file generated"
  end

  # Execute the full process
  def run
    validate_config
    generate_dockerfile
    build_and_push_image
    generate_docker_compose
    puts "All tasks completed successfully"
  end
end

if __FILE__ == $0 
  # Run the script
  if ARGV.size != 1
    puts "Usage: ruby generate_docker.rb <config.json>"
    exit 1
  end

  config_file = ARGV[0]

  begin
    generator = DockerAppGenerator.new(config_file)
    generator.run
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
end


=begin
Example config file:
{
  "RUBY_APPLICATION_DIRECTORY": "./my_ruby_app",
  "RUBY_APPLICATION_NAME": "my_ruby_app",
  "PORT": 3000
}
=end
