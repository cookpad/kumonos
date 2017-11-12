FROM ruby:2.4

RUN gem i bundler --no-doc
RUN mkdir -p /kumonos/lib/kumonos
COPY lib/kumonos/version.rb /kumonos/lib/kumonos/
COPY Gemfile Gemfile.lock kumonos.gemspec /kumonos/
WORKDIR /kumonos
RUN bundle install
COPY . /kumonos
