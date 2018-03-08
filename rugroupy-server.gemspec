# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'rugroupy-server'
  s.version = '0.1.2'

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Ryan Wynn']
  s.date = '2011-08-22'
  s.description = 'a sinatra based server which enables a http interface to rugroupy'
  s.email = 'ryan.m.wynn@gmail.com'
  s.extra_rdoc_files = [
    'LICENSE.txt',
    'README.rdoc'
  ]
  s.files = [
    'lib/rugroupy/server.rb',
    'lib/rugroupy/server_default.rb'
  ]
  s.homepage = 'http://github.com/rwynn/rugroupy-server'
  s.licenses = ['MIT']
  s.require_paths = ['lib']
  s.rubygems_version = '1.8.6'
  s.summary = 'an http interface to rugroupy'

  if s.respond_to? :specification_version
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0')
      s.add_runtime_dependency('bson', ['>= 1.3.1'])
      s.add_runtime_dependency('bson_ext', ['>= 1.3.1'])
      s.add_runtime_dependency('json', ['>= 1.5.3'])
      s.add_runtime_dependency('mongo', ['>= 1.3.1'])
      s.add_runtime_dependency('rugroupy', ['>= 0.1.0'])
      s.add_runtime_dependency('sinatra', ['>= 1.2.6'])
      s.add_runtime_dependency('sinatra-mongo', ['>= 0.1.0'])
      s.add_runtime_dependency('SystemTimer', ['>= 1.2.3'])
      s.add_development_dependency('bundler', ['~> 1.0.0'])
      s.add_development_dependency('httparty', ['>= 0.7.8'])
      s.add_development_dependency('jeweler', ['~> 1.6.4'])
      s.add_development_dependency('rcov', ['>= 0'])
      s.add_development_dependency('shoulda', ['>= 0'])
    else
      s.add_dependency('bson', ['>= 1.3.1'])
      s.add_dependency('bson_ext', ['>= 1.3.1'])
      s.add_dependency('bundler', ['~> 1.0.0'])
      s.add_dependency('httparty', ['>= 0.7.8'])
      s.add_dependency('jeweler', ['~> 1.6.4'])
      s.add_dependency('json', ['>= 1.5.3'])
      s.add_dependency('mongo', ['>= 1.3.1'])
      s.add_dependency('rugroupy', ['>= 0.1.0'])
      s.add_dependency('sinatra', ['>= 1.2.6'])
      s.add_dependency('sinatra', ['>= 1.2.6'])
      s.add_dependency('sinatra', ['>= 1.2.6'])
      s.add_dependency('sinatra-mongo', ['>= 0.1.0'])
      s.add_dependency('sinatra-mongo', ['>= 0.1.0'])
    end
  else
    s.add_dependency('rcov', ['>= 0'])
    s.add_dependency('rugroupy', ['>= 0.1.0'])
    s.add_dependency('shoulda', ['>= 0'])
    s.add_dependency('sinatra', ['>= 1.2.6'])
    s.add_dependency('sinatra-mongo', ['>= 0.1.0'])
    s.add_dependency('sinatra-mongo', ['>= 0.1.0'])
    s.add_dependency('sinatra-mongo', ['>= 0.1.0'])
    s.add_dependency('SystemTimer', ['>= 1.2.3'])
    s.add_dependency('SystemTimer', ['>= 1.2.3'])
    s.add_dependency('SystemTimer', ['>= 1.2.3'])
    s.add_dependency('SystemTimer', ['>= 1.2.3'])
    s.add_dependency('SystemTimer', ['>= 1.2.3'])
    s.add_dependency('SystemTimer', ['>= 1.2.3'])
  end
end
