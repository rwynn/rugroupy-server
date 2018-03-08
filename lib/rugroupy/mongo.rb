require 'sinatra/base'
require 'mongo'

module Sinatra
  module MongoHelper
    def mongo
      settings.mongo
    end
  end

  module MongoExtension
    def mongo=(url)
      @mongo = nil
      set :mongo_url, url
      mongo
    end

    def mongo
      synchronize do
        @mongo ||= begin
          url = URI(mongo_url)
          client = Mongo::Client.new(mongo_url)
          mongo = Mongo::Database.new(client, url.path[1..-1], mongo_settings)
          mongo
        end
      end
    end

    protected

    def self.registered(app)
      app.set :mongo_url, ENV['MONGO_URL'] || 'mongodb://127.0.0.1:27017/default'
      app.set :mongo_settings, {}
      app.helpers MongoHelper
    end
  end

  register MongoExtension
end
