### A Docker + Rails dev setup optimized for fast bundle


After weeks struggling on running Rails apps + Docker and having trouble with
Dockefile cache + bundle, I've found a solution (see ref) to use Docker + Rails in
dev enviroment with fast bundle installs by using a data-only container to stores Gems.

This repo is a personal setup that solves this problem. I don't know if this is a good solution
to use in production.

These scripts provision this environment:
  - Rails
  - Postgres

It generate four containers:
  - web - Rails + WEBrick
  - postgres - Only the postgres daemon, data is store in data-only container
  - data - Stores postgres data
  - bundle - A data-only container to store Gems


### Table of Contents
* [New Rails Project](#new-rails-project)
* [Existing Rails Project](#existing-rails-project)
* [Tips](#tips)

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
  gem 'rails', '4.2.5'
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
Now, your new project has been created.

After this, discomment in the Gemfile: `gem 'therubyracer', platforms: :ruby`
Now that we've changed the app's dependencies, lets build the image again:
```sh
$ docker-compose build
```

After build the image, run the containers: `docker-compose up`.
Four containers will be created. You can check them with `docker ps -a`.
Two containers should be `UP` and two `Exited`. The Exited containers are data-only.

Now you need to set the db configs in `config/database.yml`.The password is sent to the container by a environment variable that can be set in the docker-compose.yml.

In config/database.yml:
```sh
  user: postgres
  password: <%= ENV["DB_ENV_POSTGRES_PASSWORD"] %>
  host: db
```

If something goes wrong, you'll need to search for the environment variables that the web container is using:
PS: the web container must be running, to check: `$ docker-compose ps`, then:
```sh
$ docker exec -it <running_web_container_name> env
```
Look up for the right environment varible and change in the config/database.yml.



### Existing Rails Project
First clone:
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

If something goes wrong, you'll need to search for the environment variables that the web container is using:
PS: the web container must be running, to check: `$ docker-compose ps`, then:
```sh
$ docker exec -it <running_web_container_name> env
```
Look up for the right environment varible and change in the config/database.yml.



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
This command will copy the 'old latest' image and rename it to <none>.
The new image will be the appname_web:latest.
The tip is: rename the old and avoid `<none>` images after run build.
```sh
$ docker tag <none_id> app_web:<version>
```
