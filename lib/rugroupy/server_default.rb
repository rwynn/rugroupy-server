require 'rugroupy/server'

# This default server is used for testing
class ServerDefault < Groupy::GroupyServer
  register Sinatra::MongoExtension
  set :mongo, 'mongodb://localhost:27017/test'
end

ServerDefault.run!
