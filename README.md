
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

* [Required Installations](#required-installations)
  * [Installing](#installing)
  * [Instructions](#instructions)
  * [Testing](#testing)
* [Development](#development)
  * [Development Workflow](#development-workflow)
  * [Releasing a New Version](#releasing-a-new-version)
  * [Contribution Guidelines](#contribution-guidelines)
* [Contact](#contact)
* [Contributing](#contributing)
* [License](#license)
* [Code of Conduct](#code-of-conduct)
* [Show your support](#show-your-support)

### It's time we start doing multitenancy right! You can avoid creating a separate Postgres schema/databases for each customer or trying to ensure the WHERE clause of every single query includes the particular company. Just integrate PgRls seamlessly to your application

### This gem will integrate PostgreSQL RLS to help you develop a great multitenancy application

## Required Installations

### Installing

Add this line to your application's Gemfile:

```ruby
gem 'pg_rls'
```

And then execute:

    bundle install

Or install it yourself with:

    gem install pg_rls

### Instructions

```bash
rails generate pg_rls:install company #=> where company eq tenant model name
```

You can change company to anything you'd like, for example, `tenant`.
This will generate the model and inject all the required code.

For any new model that needs to be under RLS, you can generate it by writing:

```bash
rails generate pg_rls user #=> where user eq model name
```

and it will generate all the necessary information for you.

You can switch to another tenant by using:

```ruby
PgRls::Tenant.switch :app #=> where app eq tenant name
```

### Testing

If you are getting `PG::InsufficientPrivilege: ERROR:  permission denied`, you can override those permissions by running:

```bash
RAILS_ENV=test rake db:grant_usage
```

Many applications use some sort of database cleaner before running their specs so on each test run, you'll have an empty state. Usually, those gems clear user configuration for the database. To solve this issue, implement the following:

```ruby
# spec/rails_helper.rb

# some database cleaning strategy

config.before(:suite) do
  # Create the tenant, which in this example is company, and we are using FactoryBot
  FactoryBot.create(:company, subdomain: 'app')
  # In this default case, our initializer is set to search by subdomain so will use it
  PgRls::Tenant.switch :app
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Development Workflow

Before each push, you **must** follow this workflow to ensure code quality and compliance:

1. **Run Quality Checks:**

   Use the following command to ensure all checks pass before committing your code:

   ```bash
   ./review_code.sh
   ```

   This script performs the following checks:
   * **Rubocop**: Ensures there are no style violations.
   * **RSpec**: Runs the test suite. Code coverage must remain at **100%**.
   * **Steep**: Type checks using RBS. All type errors must be resolved.

   **Note**: The `rbs collection` is committed to the repository, so developers don't need to run `rbs collection install`. Just make sure the collection is up to date when setting up the project.

2. **Documentation Coverage**:

   All methods, classes, and modules must be fully documented. Documentation coverage should remain at **100%**. Use tools like `yard` to verify that your documentation is complete.

3. **Running Tests**:

   Run tests using:

   ```bash
   bundle exec rspec
   ```

   Ensure that all tests pass before committing code and that test coverage is complete.

### Releasing a New Version

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Contribution Guidelines

* **Code coverage** must remain at **100%**.
* **Documentation coverage** must also remain at **100%**.
* **No Rubocop errors** are acceptable.

Bug reports and pull requests are welcome on GitHub at <https://github.com/dandush03/pg_rls>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/dandush03/pg_rls/blob/master/CODE_OF_CONDUCT.md).

## Contact

If you need help, feel free to reach out through the repository [issues](https://github.com/dandush03/pg_rls/issues) page or contact me via [LinkedIn](https://www.linkedin.com/in/daniel-laloush/).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PgRls project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/dandush03/pg_rls/blob/master/CODE_OF_CONDUCT.md).

## Show Your Support

Give a ⭐️ if you like this project!

If this project helps you reduce development time, you can buy me a cup of coffee :)

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
[linkedin-shield2]: https://img.shields.io/badge/-LinkedIn-black.svg?style=flat-square&logo=linkedin&colorB=555
[linkedin-url2]: https://www.linkedin.com/in/daniel-laloush
