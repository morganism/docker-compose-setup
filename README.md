[![Ruby](https://github.com/morganism/docker-compose-setup/actions/workflows/ruby.yml/badge.svg)](https://github.com/morganism/docker-compose-setup/actions/workflows/ruby.yml)

# Docker Compose Setup

## the ./docker directory contains directories that have ```docker-compose.yml``` each one wil launch the image into docker using the command ```docker-compose up -d``` sometimes ```docker compose up -d``` such as on OSX 


## ```./bin/docker_generator.rb``` will take a directory containing a ruby app and create a docker-compose.yaml that will launch that application in a container

### requirements
 
- config.json : a file containing the necessary config vars for deployment 

```
{
  "RUBY_APPLICATION_DIRECTORY": "./my_ruby_app",
  "RUBY_APPLICATION_NAME": "my_ruby_app",
  "PORT": 3000
}
```
