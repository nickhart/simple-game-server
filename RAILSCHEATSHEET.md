# Rails Command Cheat Sheet

## Database Management

| Command | Description |
|---------|-------------|
| `rails db:create` | Create the database |
| `rails db:drop` | Drop the database |
| `rails db:migrate` | Run pending migrations |
| `rails db:rollback` | Roll back the last migration |
| `rails db:reset` | Drop, create, and migrate the database |
| `rails db:seed` | Seed the database with initial data |
| `rails db:version` | Show the current schema version |

## Server Management

| Command | Description |
|---------|-------------|
| `rails server` or `rails s` | Start the Rails server |
| `rails server -p 3001` | Start the server on a different port |
| `rails server -b 0.0.0.0` | Start the server on all interfaces |
| `rails server -e production` | Start the server in production mode |

## Console

| Command | Description |
|---------|-------------|
| `rails console` or `rails c` | Start the Rails console |
| `rails console -s` | Start the console in sandbox mode |
| `rails console -e production` | Start the console in production mode |

## Generators

| Command | Description |
|---------|-------------|
| `rails generate model User name:string email:string` | Generate a model with attributes |
| `rails generate controller Users index show` | Generate a controller with actions |
| `rails generate migration AddTitleToPosts title:string` | Generate a migration |
| `rails generate scaffold Post title:string content:text` | Generate a full CRUD scaffold |
| `rails generate resource User name:string email:string` | Generate a resource (model, controller, routes) |

## Testing

| Command | Description |
|---------|-------------|
| `rails test` | Run all tests |
| `rails test test/models/user_test.rb` | Run a specific test file |
| `rails test:system` | Run system tests |
| `rails test:prepare` | Prepare test database |

## Routes

| Command | Description |
|---------|-------------|
| `rails routes` | List all routes |
| `rails routes | grep users` | Filter routes by name |

## Assets

| Command | Description |
|---------|-------------|
| `rails assets:precompile` | Precompile assets for production |
| `rails assets:clean` | Clean old compiled assets |

## Environment Variables

| Command | Description |
|---------|-------------|
| `RAILS_ENV=production rails server` | Start server in production mode |
| `RAILS_LOG_LEVEL=debug rails server` | Start server with debug logging |

## Other Useful Commands

| Command | Description |
|---------|-------------|
| `rails new my_app` | Create a new Rails application |
| `rails destroy model User` | Remove a generated model |
| `rails destroy controller Users` | Remove a generated controller |
| `rails destroy migration AddTitleToPosts` | Remove a generated migration |
| `rails destroy scaffold Post` | Remove a generated scaffold |
| `rails destroy resource User` | Remove a generated resource |
| `rails destroy model User --force` | Force remove a model |
| `rails destroy controller Users --force` | Force remove a controller |
| `rails destroy migration AddTitleToPosts --force` | Force remove a migration |
| `rails destroy scaffold Post --force` | Force remove a scaffold |
| `rails destroy resource User --force` | Force remove a resource |
| `rails destroy model User --skip-migration` | Remove a model without migration |
| `rails destroy controller Users --skip-routes` | Remove a controller without routes |
| `rails destroy scaffold Post --skip-migration` | Remove a scaffold without migration |
| `rails destroy resource User --skip-migration` | Remove a resource without migration |
| `rails destroy model User --skip-migration --force` | Force remove a model without migration |
| `rails destroy controller Users --skip-routes --force` | Force remove a controller without routes |
| `rails destroy scaffold Post --skip-migration --force` | Force remove a scaffold without migration |
| `rails destroy resource User --skip-migration --force` | Force remove a resource without migration |
