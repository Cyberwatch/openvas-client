# OpenvasClient

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/openvas_api`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openvas_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install openvas_client

## Usage

Init agent with default values => `host: localhost, port: 9390, user: admin, password: openvas`

    openvas = OpenVASClient::OpenVASAgent.new()

You can create a target (**target's name can't contain spaces**)

    target = openvas.user.create_target('target_name', host)

or find it with its name

    target = openvas.user.find_target_by_name('target_name')

You can also create a task

    task = openvas.user.create_task('task_name', target)

Now you can start, stop and resume this task

    task.start
    task.stop
    task.resume

Finally, results and report can be imported in JSON format

    task.results
    task.report

User's tasks and targets (both an array) are accessible with these commands

    openvas.user.targets
    openvas.user.tasks

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/openvas_api.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

