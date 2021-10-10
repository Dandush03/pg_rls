# PgRls

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/pg_rls`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pg_rls'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install pg_rls

## Usage

RUN `rails generate pg_rls:install company`

You can change company to anything you'd like like for example `tenant`
this will generate the model and inject all the required code

for any new model that required to be under rls you can generate it by writing 

`rails generate pg_rls user`
and it will generate all the necesary information for you

enjoy the gem :) 
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dandush03/pg_rls. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/dandush03/pg_rls/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PgRls project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dandush03/pg_rls/blob/master/CODE_OF_CONDUCT.md).
