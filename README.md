Toro
====
Full-featured background processing for Ruby & PostgreSQL

Overview
--------

Toro is a job queueing system (similar to Sidekiq or Resque) that runs on PostgreSQL and focuses on concurrency, visibility, extensibility, and durability:

#### Concurrency
* Toro can run many jobs simultaneously in a single process (a la Sidekiq; it uses [Celluloid](https://github.com/celluloid/celluloid))

#### Visibility

An extensive dashboard:

* Sort jobs by queue, worker, start time, queued time, duration, customizable name, status
* Filter jobs by queue, worker, customizable name, status
* Stacked histograms show the status distribution for each queue
* A process table showing which machines/processes are active and which jobs they're running
* Buttons for manually retrying failed jobs
* Job detail view with in-depth job information:
  * Basics: worker class, arguments, start time, duration, process name
  * Exception class, message, and backtrace of failed jobs
  * A list of the exceptions and start times of retried jobs
  * Customizable job properties

#### Extensibility
* Middleware support
* Customizable UI views
* Customizable job names
* Customizable job properties
  * Store job-related metadata that's set during the job's execution
  * Stored in an hstore
    * Properties can be indexed and queried against
    * Jobs can be associated with other ActiveRecord models using a property as the foreign key

#### Durability
* Toro runs on PostgreSQL

#### Other Features
* Scheduled jobs
* Configurable retry of failed jobs

#### UI

Toro has an extensive dashboard that provides in-depth information about jobs, queues, processes, and more:

[<img src="https://raw.github.com/tombenner/toro/master/examples/jobs.png" width="48%" />](https://raw.github.com/tombenner/toro/master/examples/jobs.png)
[<img src="https://raw.github.com/tombenner/toro/master/examples/job.png" width="48%" />](https://raw.github.com/tombenner/toro/master/examples/job.png)
[<img src="https://raw.github.com/tombenner/toro/master/examples/queues.png" width="48%" />](https://raw.github.com/tombenner/toro/master/examples/queues.png)
[<img src="https://raw.github.com/tombenner/toro/master/examples/chart.png" width="48%" />](https://raw.github.com/tombenner/toro/master/examples/chart.png)

Installation
------------

Add Toro to your Gemfile:

```ruby
gem 'toro'
```

Mount the UI at a route in `routes.rb`:

```ruby
mount Toro::Monitor::Engine => '/toro'
```

And install and run the migration:

```bash
rails g toro:install
rake db:migrate
```

Quick Start
-----------

Create a worker:

```ruby
# app/workers/my_worker.rb
class MyWorker
  include Toro::Worker

  def perform(user_id)
    puts "Processing user #{user_id}..."
  end
end
```

In your controller action, model, or elsewhere, queue a job:
```ruby
MyWorker.perform_async(15)
```

Start Toro in the root directory of your Rails app:
```bash
rake toro
```

Basics
------

### Queues

By default, workers and processes use the `default` queue.

To set a worker's queue, use `toro_options`:

```ruby
# app/workers/my_worker.rb
class MyWorker
  include Toro::Worker
  toro_options queue: 'users'

  def perform(user_id)
    puts "Processing user #{user_id}..."
  end
end
```

To set a process's queue, use `-q`:

```bash
rake toro -- -q users
```

Or specify multiple queues:

```bash
rake toro -- -q users -q comments
```

### Concurrency

To specify a process's concurrency (how many jobs it can run simultaneously), use `-c`:

```bash
rake toro -- -c 10
```

### Scheduled Jobs

To schedule a job for a specific time, use `perform_in(interval, *args)` or `perform_at(timestamp, *args)` instead of the standard `perform_async(*args)`:

```ruby
MyWorker.perform_in(2.hours, 'First arg', 'Second arg')
MyWorker.perform_at(2.hours.from_now, 'First arg', 'Second arg')
```

### Retrying Jobs

Failing jobs aren't retried by default. If you'd like Toro to retry a worker's failed jobs, specify the retry interval in the worker:

```ruby
# app/workers/my_worker.rb
class MyWorker
  include Toro::Worker
  toro_options retry_interval: 2.hours

  def perform(user_id)
    puts "Processing user #{user_id}..."
  end
end
```

The error classes and times of retried jobs are stored as job properties.

### Querying Jobs

`Toro::Job` is an ActiveRecord model, which allows you to easily create complex queries against jobs that aren't easily performed in Redis-based job queueing systems. The model has the following columns:

* queue - Queue
* class_name - Worker class
* args - Arguments
* name - Name
* created_at - When the job was created
* scheduled_at - When the job was scheduled for (if it's a scheduled job)
* started_at - When the job was started
* finished_at - When the job finished (regardless of whether it succeeded or failed)
* status - `queued`, `running`, `complete`, `failed`, or `scheduled`
* started_by - Host and PID of the process running the job (e.g. `ip-10-55-10-151:1623`)
* properties - An hstore containing customizable job properties


Job Customization
-----------------

### Job Name

To set a job's name, define a `self.job_name` method that takes the same arguments the `perform` method:

```ruby
class MyWorker
  include Toro::Worker

  def perform(user_id)
  end

  def self.job_name(user_id)
    User.find(user_id).username
  end
end
```

A job name makes the job more recognizable in the UI. The UI also lets you search by name.

### Job Properties

Job properties let you store custom data about your jobs and their results.

To set job properties, make the `perform` method return a hash with a `:job_properties` key:

```ruby
class MyWorker
  include Toro::Worker

  def perform(user_id)
    comments = User.find(user_id).comments
    # Do some processing...
    {
      job_properties: {
        user_id: user_id,
        comments_count: comments.length
      }
    }
  end
end
```

The job properties will be shown in the job detail view in the UI.

Properties are stored using [Nested Hstore](https://github.com/tombenner/nested-hstore), so you can store nested hashes, arrays, or any other types, allowing for NoSQL-like document storage:

```ruby
class MyWorker
  include Toro::Worker

  def perform(user_id)
    user = User.find(user_id)
    comments = user.comments
    # Do some processing...
    {
      job_properties: {
        user: {
          id: user.id,
          is_blacklisted: user.is_blacklisted?,
          timeline: {
            is_private: user.timeline.is_private
          }
        },
        comment_ids: comments.map(&:id)
      }
    }
  end
end
```

#### Querying Job Properties

Job properties are stored in an hstore, so you can query them (e.g. for reporting):

```ruby
big_jobs = Toro::Job.where("(properties->'comments_count')::int > ?", 100)
```

#### Associating Jobs with Other Models

You can create associations between jobs and other models using them:

```ruby
class User < ActiveRecord::Base
  has_many :jobs, foreign_key: "toro_jobs.properties->'user_id'", class_name: 'Toro::Job'
end
```

You can then, for example, find the failed jobs for a user:

```ruby
failed_jobs = User.find(1).jobs.where(status: 'failed')
```

Middleware
----------

Toro's middleware support lets you run code "around" the processing of a job. Writing middleware is easy:

```ruby
# lib/my_middleware.rb
class MyMiddleware
  def call(job, worker)
    begin
      puts "Starting to process Job ##{job.id}"
      yield
      puts "Finished running Job ##{job.id}"
    rescue Exception => exception
      puts "Exception raised for Job ##{job.id}: #{exception}"
      job.update_attribute(status: 'failed')
      raise exception
    end
  end
end
```

Then register your middleware as part of the chain:

```ruby
# config/initializers/toro.rb
Toro.configure_server do |config|
  config.server_middleware do |chain|
    chain.add MyMiddleware
  end
end
```

Toro supports the same server middleware inferface that Sidekiq does (including arguments, middleware removal, etc). Please see the [Sidekiq Middleware documentation](https://github.com/mperham/sidekiq/wiki/Middleware) for details.

Monitor Customization
---------------------

### Chart

A single histogram will be shown by default in the Chart view, but you can also split the queues into multiple histograms. (This is especially useful if you have a large number of queues and the single histogram has too many bars to be readable.) The keys of this hash are JS regex patterns for matching queues, and the values of the hash will be the titles of each histogram:

```ruby
# config/initializers/toro.rb
Toro::Monitor.options[:charts] = {
  'ALL' => 'All',
  'OTHER' => 'Default Priority',
  '_high$' => 'High Priority',
  '_low$' => 'Low Priority'
}
```

`ALL` and `OTHER` are special keys: `ALL` will show all queues and `OTHER` will show all queues that aren't matched by the regex keys.

### Poll Interval

The UI uses polling to update its data. By default, the polling interval is 3000ms, but you can adjust this like so:

```ruby
# config/initializers/toro.rb
Toro::Monitor.options[:poll_interval] = 5000
```

### Custom Statuses

The UI's status filter and histograms show the most common job statuses, but if you'd like to add additional statuses to them (for example, if you have added custom statuses through middleware), you can make the UI include them like so:

```ruby
# config/initializers/toro.rb
Toro::Monitor::Job.add_status('my_custom_status')
```

### Custom Job Views

When you click on a job, a modal showing its properties is displayed. You can add subviews to this modal by creating a view in your app and calling `Toro::Monitor::CustomViews.add`, passing it the subview's title, the subview's filepath, and a block. The subview is only rendered if the block evaluates to true for the given job.

If you need to add JavaScript for the subview, you can do so by adding an asset path to `Toro::Monitor.options[:javascripts]`.

For example, the following code adds a subview that shows a "Retry" button for jobs with the specified statuses:

```ruby
# config/initializers/toro.rb
view_path = Rails.root.join('app', 'views', 'toro', 'monitor', 'retry').to_s
Toro::Monitor::CustomViews.add('My View Title', view_path) do |job|
  %w{complete failed}.include?(job.status)
end
Toro::Monitor.options[:javascripts] << 'toro/monitor/retry'
```

```
/ app/views/toro/monitor/retry.slim
a class='btn btn-success' href='#' data-action='retry_job' data-job-id=job.id = 'Retry'
```

```coffee
# app/assets/javascripts/toro/monitor/retry.js.coffee
$ ->
  $('body').on 'click', '.job-modal [data-action=retry_job]', (e) ->
    id = $(e.target).attr('data-job-id')
    $.get ToroMonitor.settings.api_url("jobs/retry/#{id}")
    alert 'Job has been retried'
    false
```

### Authentication

You'll likely want to restrict access to the UI in a production environment. To do this, you can use routing constraints:

#### Devise

Checks a `User` model instance that responds to `admin?`

```ruby
constraint = lambda { |request| request.env["warden"].authenticate? and request.env['warden'].user.admin? }
constraints constraint do
  mount Toro::Monitor::Engine => '/toro'
end
```

Allow any authenticated `User`

```ruby
constraint = lambda { |request| request.env['warden'].authenticate!({ scope: :user }) }
constraints constraint do
  mount Toro::Monitor::Engine => '/toro'
end
```

Short version

```ruby
authenticate :user do
  mount Toro::Monitor::Engine => '/toro'
end
```

#### Authlogic

```ruby
# lib/admin_constraint.rb
class AdminConstraint
  def matches?(request)
    return false unless request.cookies['user_credentials'].present?
    user = User.find_by_persistence_token(request.cookies['user_credentials'].split(':')[0])
    user && user.admin?
  end
end

# config/routes.rb
require "admin_constraint"
mount Toro::Monitor::Engine => '/toro', :constraints => AdminConstraint.new
```

#### Restful Authentication

Checks a `User` model instance that responds to `admin?`

```ruby
# lib/admin_constraint.rb
class AdminConstraint
  def matches?(request)
    return false unless request.session[:user_id]
    user = User.find request.session[:user_id]
    user && user.admin?
  end
end

# config/routes.rb
require "admin_constraint"
mount Toro::Monitor::Engine => '/toro', :constraints => AdminConstraint.new
```

#### Custom External Authentication

```ruby
class AuthConstraint
  def self.admin?(request)
    return false unless (cookie = request.cookies['auth'])

    Rails.cache.fetch(cookie['user'], :expires_in => 1.minute) do
      auth_data = JSON.parse(Base64.decode64(cookie['data']))
      response = HTTParty.post(Auth.validate_url, :query => auth_data)

      response.code == 200 && JSON.parse(response.body)['roles'].to_a.include?('Admin')
    end
  end
end

# config/routes.rb
constraints lambda {|request| AuthConstraint.admin?(request) } do
  mount Toro::Monitor::Engine => '/admin/toro'
end
```

_(This authentication documentation was borrowed from the [Sidekiq wiki](https://github.com/mperham/sidekiq/wiki/Monitoring).)_


Logging
-------

Logging can be especially useful in debugging concurrent systems like Toro. You can modify Toro's logger:


```ruby
# config/initializers/toro.rb

# Adjust attributes of Toro's logger
Toro.logger.level = Logger::DEBUG

# Or create a custom Logger
Toro.logger = Logger.new(Rails.root.join('log', 'toro.log'))
Toro.logger.level = Logger::DEBUG

```

See the [Logger docs](http://www.ruby-doc.org/stdlib-2.0/libdoc/logger/rdoc/Logger.html) for more.

Testing
-------

Copy and set up the database config:

```bash
cp spec/config/database.yml.example spec/config/database.yml
```

Toro is tested against Rails 3 and 4, so please run the tests with [Appraisal](https://github.com/thoughtbot/appraisal) before submitting a PR. Thanks!

```bash
appraisal rspec
```

FAQ
---

### Toro?
* [Toro](http://en.wikipedia.org/wiki/Tuna) is robust, quick, and values strength in numbers.
* [Toro](http://en.wikipedia.org/wiki/Bull) is durable and runs a little large.
* [Toro](http://en.wikipedia.org/wiki/T%C5%8Dr%C5%8D) brings visibility.


Notes
-----

A good deal of architecture and code was borrowed from [@mperham](https://github.com/mperham)'s excellent [Sidekiq](https://github.com/mperham/sidekiq), so many thanks to him and all of Sidekiq's contributors!

License
-------

Toro is released under the MIT License. Please see the MIT-LICENSE file for details.
