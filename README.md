# OpenVASClient

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openvas_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install openvas_client

OpenVAS is obviously required and I strongly recommend you to use a container to get OpenVAS. I used this one : https://hub.docker.com/r/mikesplain/openvas/

## Usage

### Initialisation

Init agent with default values from my Docker container
`host: localhost, port: 9390, user: admin, password: openvas`

```ruby
agent = OpenVASClient::OpenVASAgent.new()
```

Up to you to custom your initialisation with an existing user like this

```ruby
agent = OpenVASClient::OpenVASAgent.new('127.0.0.1', 8080, 'my_user', 'my_password')
```

### Target

You can create a target (**target's name can't contain spaces**)

```ruby
target = agent.user.create_target('target_name', host)
```

or find it with its name

```ruby
target = agent.user.find_target_by_name('target_name')
```

### Task

You can also create a task

```ruby
task = agent.user.create_task('task_name', target)
```

or find it with its name

```ruby
task = agent.user.find_task_by_name('task_name')
```

Now you can start, stop and resume this task

```ruby
task.start
task.stop
task.resume
```

You can obtain information about current status by getting task information

```ruby
task.status
```

Finally, results and report can be imported in JSON format

```ruby
task.results
task.report
```

### User

A user is loaded by default when you launch the agent (cf Initialisation). Once logged, you can create another user.
**Username can't contain spaces**

```ruby
OpenVASApi::User.new(name, password, agent)
```

If you want to visualize all users, you can do

```ruby
OpenVASApi::User.users(agent)
```

To delete a user (except the current user of course)

```ruby
OpenVASApi::User.destroy(user_id, agent)
```

### Other options

User's tasks and targets (both an array) are accessible with these commands

```ruby
agent.user.targets
agent.user.tasks
```

To remove specific task or target, just do

```ruby
agent.user.destroy_task('task_name')
agent.user.destroy_target('target_name')
```

Please notice that you can't remove a task or a target if the scan is running. Moreover, you can't delete a target linked to an existing task. You have to remove it first.

If you want to delete old tasks and only keep three most recents

```ruby
agent.user.clean_tasks
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

I used the official documentation to create this gem : http://docs.greenbone.net/API/OMP/omp-6.0.html

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Cyberwatch/openvas_client.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
