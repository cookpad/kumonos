# Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

If you've installed [docker-compose](https://docs.docker.com/compose/), you can run the integration tests by `rake integration_test`. To run all the tests, `rake all`.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, use `bump`, and then run `rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org/).
