### A Docker + Rails dev setup optimized for fast bundle


### 2020 update

See this repos, probably a better aproach:
```
https://github.com/ledermann/docker-rails-base
https://github.com/ledermann/docker-rails
```

### ...

After weeks struggling with Rails apps + Docker and having trouble with
Dockefile cache + Bundler, I've found a solution (see [ref](#references)) to use Docker + Rails in
dev environment with fast bundle installs by using a data-only container to stores Gems.

This repo is a personal setup that solves this problem. I don't know if this is a good solution
to use in production.

These scripts are provisioning the following environment:
  - Rails
  - Postgres

It generates four containers:
  - web - Rails + WEBrick
  - postgres - Only the postgres daemon, data is store in data-only container
  - data - Stores postgres data
  - bundle - A data-only container to store Gems


### Table of Contents
* [New Rails Project](#new-rails-project)
* [Existing Rails Project](#existing-rails-project)
* [Tips](#tips)
* [References](#references)

### New Rails Project
To use this repo in a new rails project, first clone:
```sh
$ git clone https://github.com/emanuelhfarias/Docker-Rails-setup.git
```

Create a new folder for you app: `mkdir appname`
Then, copy these two files from the repo directory to your app folder:
```sh
$ cd Docker-Rails-setup
$ cp Dockerfile docker-compose.yml /your/app/home/folder/
```

Change to the app folder, then create the Gemfile only with rails gem:
```sh
  source 'https://rubygems.org'
  gem 'rails', '5.0.0.1'
```

Create the Gemfile.lock: `touch Gemfile.lock`

Make sure to have this four files:
- Dockerfile
- docker-compose.yml
- Gemfile
- Gemfile.lock

Now it's time to create the rails project and the first docker image version, run:
```sh
$ docker-compose run web rails new . --force --database=postgresql --skip-bundle
```
Your new project has been created.

Uncomment in the Gemfile: `gem 'therubyracer', platforms: :ruby`
Now that we've changed the app's dependencies, lets build the image again:
```sh
$ docker-compose build
```

Now you need to set the db configs in `config/database.yml`.The password is sent to the container by a environment variable that can be set in the docker-compose.yml.

In config/database.yml:
```sh
  user: postgres
  password: <%= ENV["DB_ENV_POSTGRES_PASSWORD"] %>
  host: db
```

Create the volume in the host to store the database: `sudo mkdir -p /var/lib/postgresql/data`.
Give SELinux permission to Docker expose the database volume: `sudo chcon -Rt svirt_sandbox_file_t /var/lib/postgresql/data`.

Lets spawn the containers: `docker-compose up`.
Four containers will be created. You can check them with `docker ps -a`.
Two containers should be `UP` and two `Exited`. The Exited containers are data-only.
Go to `localhost:3000` and check.

If something goes wrong with `database connection` you'll need to search for the environment variables that the web container is using:
```sh
$ docker exec -it <running_web_container_name> env
```
PS: To run `docker exec` the web container must be running. If web container is exiting automatically, try to inspect environment variables using `docker run -it --rm <web_image_name> env`.
Look up for the right environment varible and change in the config/database.yml.

After database connection established, create db and run migrations:
```sh
$ docker exec <running_web_container_name> rails db:create db:migrate
```
That's it. Go to `localhost:3000` and check it again.


### Existing Rails Project
To use this repo in an existing project, first clone:
```sh
$ git clone https://github.com/emanuelhfarias/Docker-Rails-setup.git
```

Copy these two files from the repo directory to your app folder:
```sh
$ cd Docker-Rails-setup
$ cp Dockerfile docker-compose.yml /your/app/home/folder/
```

Change current dir to your app folder: `cd /your/app/home/folder/`

Before build the image, make sure you have the Gemfile and Gemfile.lock.
If you don't have the Gemfile.lock, then:
`$ touch Gemfile.lock`

Build the image
`$ docker-compose build`

Now you need to set the db configs in `config/database.yml`.The password is sent to the container by a environment variable that can be set in the docker-compose.yml.

In config/database.yml:
```sh
  user: postgres
  password: <%= ENV["DB_ENV_POSTGRES_PASSWORD"] %>
  host: db
```

Lets spawn the containers: `docker-compose up`.
Four containers will be created. You can check them with `docker ps -a`.
Two containers should be `UP` and two `Exited`. The Exited containers are data-only.
Go to `localhost:3000` and check.

If something goes wrong with `database connection` you'll need to search for the environment variables that the web container is using:
```sh
$ docker exec -it <running_web_container_name> env
```
PS: To run `docker exec` the web container must be running. If web container is exiting automatically, try to inspect environment variables using `docker run -it --rm <web_image_name> env`.
Look up for the right environment varible and change in the config/database.yml.

After database connection established, create db and run migrations:
```sh
$ docker exec <running_web_container_name> rails db:create db:migrate
```
That's it. Go to `localhost:3000` and check it again.



### Tips

By default, the image generated by Dockerfile contains a 'normal user'.
Try to execute commands inside the container using this user.

The exception is `bundle install`, that will run as root.

Command: `bundle install`
```sh
$ docker exec -u root <running_web_container_name> bundle install
```
You don't need to rebuild the image in the development environment.
But in production, maybe is a good idea to have the bundle gems within web image.


Command: `rails db:create OR db:migrate`
```sh
$ docker exec <running_web_container_name> rails db:create db:migrate
```

Command: `rails g scaffold post title:string body:text`
```sh
$ docker exec <running_web_container_name> rails g scaffold post title:string body:text
```

Before deploy in production, rebuild the image `$ docker-compose build`.
This command will copy the 'old latest' image and rename it to `<none>`.
The new image will be the appname_web:latest.
The tip is: rename the old images after rebuild to and avoid `<none>`.
```sh
$ docker tag <none_id> app_web:<version>
```


### References
* Bundle container
  * http://bradgessler.com/articles/docker-bundler/
  * http://www.atlashealth.com/blog/2014/09/persistent-ruby-gems-docker-container/#.VpmxmSCrS00

* Bundle vendor/cache (alternative solution)
  * http://simonrobson.net/2014/10/14/private-git-repos-on-docker-images.html
  * https://viget.com/extend/bundler-best-practices

* Util
  * https://forums.docker.com/t/swiching-between-root-and-non-root-users-from-interactive-console/2269
  * https://docs.docker.com/compose/rails/
