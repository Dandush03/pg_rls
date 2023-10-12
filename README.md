<!--
  Title: PgRls Rails
  Description: rails multitenancy with pg rls
  Author: dandush03
  -->
<meta name="google-site-verification" content="Mc1vBv8PRYPw_cdd3EiKhF2vlOeIEIk3VYhAg75ertI" />

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![LinkedIn][linkedin-shield2]][linkedin-url2]
[![Hireable][hireable]][hireable-url]
[![Donate][donate]][paypal-donate-code]

<!-- PROJECT LOGO -->
<br />
<p align="center">
 <h1 align="center">PgRls<h2 align="center">PostgreSQL Row Level Security<br />The Rails right way to do multitenancy</h2></h1>

  <p align="center">
    <br />
    <a href="https://github.com/Dandush03/pg_rls/wiki"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/Dandush03/pg_rls/issues">Report Bug</a>
    ·
    <a href="https://github.com/Dandush03/pg_rls/issues">Request Feature</a>
    ·
    <a href="https://github.com/Dandush03/pg_rls">API Repo</a>
  </p>

</p>

### Table of Contents
* [Required Installations](#required-Installations)
  * [Installing](#installing)
  * [Instructions](#instructions)
  * [Testing](#Testing)
* [Development](#testing)
* [Contact](#contact)
* [Contributing](#contributing)
* [License](#license)
* [Code of Conduct](#Code-of-Conduct)
* [Show your support](#Show-your-support)

### It's time we start doing multitenancy right! You can avoid creating a separate Postgres schema/databases for each customer or trying to ensure the WHERE clause of every single query includes the particular company. Just integrate PgRls seamlessly to your application.

### This gem will integrate PostgreSQL RLS to help you develop a great multitenancy application.

## Required Installation
### Installing

Add this line to your application's Gemfile:

```ruby
gem 'pg_rls'
```

And then execute:

    $ bundle install

Or install it yourself with:

    $ gem install pg_rls

### Instructions

```bash
rails generate pg_rls:install company #=> where company eq tenant model name
```
You can change company to anything you'd like, for example, `tenant`
This will generate the model and inject all the required code

For any new model that needs to be under rls, you can generate it by writing

```bash
rails generate pg_rls user #=> where user eq model name
```
and it will generate all the necesary information for you.

You can swtich to another tenant by using
```ruby
PgRls::Tenant.switch :app #=> where app eq tenant name
```
Don't forget to update how you want `PgRls` to find your tenant, you can set multiple options by modifying `api/config/initializers/pg_rls.rb` `search_methods`

```yml
# app/config/database.yml
<% def db_username
    return PgRls.username unless ENV['AS_DB_ADMIN']

    Rails.application.credentials.dig(:database, :server_1, :username)
   end %>

...

development:
  <<: *default
  database: example_development
  username: <%= db_username %> # Apply this to production and all env including tests

...

```
### Testing

If you are getting `PG::InsufficientPrivilege: ERROR:  permission denied ` you can override does permistion by running `RAILS_ENV=test rake db:grant_usage`

Many application uses some sort of database cleaner before running thair spec so on each test that we run we'll have an empty state. Usually, those gems clear our user configuration for the database. To solve this issue, we must implement the following:

```ruby
# spec/rails_helper.rb

...
# some database cleaning strategy

config.before(:suite) do
  # Create the tenant which in this example is company and we are using FactoryBot
  FactoryBot.create(:company, subdomain: 'app')
  # In this default case our initializer is set to search by subdomain so will use it
  PgRls::Tenant.switch :app
end

...
```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dandush03/pg_rls. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/dandush03/pg_rls/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PgRls project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dandush03/pg_rls/blob/master/CODE_OF_CONDUCT.md).

## Note
Currently we only support subdomain as a searcher but will soon integrate slug/domain and cookies support
we recommed the use of ``
## Show your support

Give a ⭐️ if you like this project!

If this project help you reduce time to develop, you can give me a cup of coffee :)

[![paypal][paypal-url]][paypal-donate-code]

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/Dandush03/React-Calculator.svg?style=flat-square
[contributors-url]: https://github.com/Dandush03/pg_rls/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/Dandush03/pg_rls.svg?style=flat-square
[forks-url]: https://github.com/Dandush03/pg_rls/network/members
[stars-shield]: https://img.shields.io/github/stars/Dandush03/pg_rls.svg?style=flat-square
[stars-url]: https://github.com/Dandush03/pg_rls/stargazers
[issues-shield]: https://img.shields.io/github/issues/Dandush03/pg_rls.svg?style=flat-square
[issues-url]: https://github.com/Dandush03/pg_rls/issues
[license-shield]: https://img.shields.io/github/license/Dandush03/pg_rls.svg?style=flat-square
[license-url]: https://github.com/Dandush03/pg_rls/blob/master/LICENSE.txt
[linkedin-shield2]: https://img.shields.io/badge/-LinkedIn-black.svg?style=flat-square&logo=linkedin&colorB=555
[linkedin-url2]: https://www.linkedin.com/in/daniel-laloush/
[hireable]: https://cdn.rawgit.com/hiendv/hireable/master/styles/flat/yes.svg
[paypal-url]: https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif
[paypal-donate-code]: https://www.paypal.com/donate?hosted_button_id=QKZFZAMQNC8JL
[hireable-url]: https://www.linkedin.com/in/daniel-laloush/
[donate]: https://img.shields.io/badge/Donate-PayPal-blue.svg
