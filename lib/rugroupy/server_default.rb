require 'rugroupy/server'

# This default server is used for testing
class ServerDefault < Groupy::GroupyServer
  register Sinatra::MongoExtension
  set :mongo, 'mongo://localhost:27017/test'
end

ServerDefault.run!