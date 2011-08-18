require 'rubygems'
require 'sinatra/base'
require 'sinatra/mongo'
require 'rugroupy'
require 'json'

# Run the server like this by extending GroupyServer and calling run!
# require 'rugroupy/server'
# class MyApp < GroupyServer 
#   register Sinatra::MongoExtension
#   set :mongo, 'mongo://localhost:27017/test'
# end
# MyApp.run!

module GroupyServerSupport
  
  def get_entity(params, create=false)
    e_json = self.get_entity_json(params)
    e = Groupy::Entity.new(mongo, e_json['name'], e_json["id"], create)
    e.get
  end
  
  def get_entity_json(params)
    JSON.parse(params[:entity])
  end
  
  def get_entity_similiar(params)
    e_json = self.get_entity_json(params)
    e = Groupy::Entity.new(mongo, e_json['name'], e_json["id"], create=false)
    e.similiar(e_json["tag"], e_json["skip"], e_json["limit"], e_json["reverse"])
  end
  
  def delete_entity(params)
    e_json = self.get_entity_json(params)
    e = Groupy::Entity.new(mongo, e_json['name'], e_json["id"], create=create)
    e.delete
  end
  
  def tag_entity(params, create=true)
    e_json = self.get_entity_json(params)
    e = Groupy::Entity.new(mongo, e_json['name'], e_json["id"], create=create)
    e_json["tags"].each_pair do |name, value|
      create ? e.tag(name, value) : e.untag(name, value)
    end
    e.get
  end
  
  def group_entities(params)
    e_json = self.get_entity_json(params)
    g = Groupy::EntityGrouper.new(mongo, e_json["name"])
    options = {:includeFunction => e_json["include_function"], 
      :scoreFunction => e_json["score_function"],
      :dynamicTagFunction => e_json["dynamic_tag_function"]}
    g.group(options)
  end

  def similiar_entities(params)
    e_json = self.get_entity_json(params)
    g = Groupy::EntityGrouper.new(mongo, e_json["name"])
    g.similiar(e_json["tag"], e_json["skip"], e_json["limit"], e_json["reverse"])
  end
  
end

class GroupyServer < Sinatra::Base
  include GroupyServerSupport
  #register Sinatra::MongoExtension
  #set :mongo, 'mongo://localhost:27017/test'
  
  before do 
    headers "Content-Type"   => "application/json; charset=UTF-8"
  end
  
  get '/entity' do
    response = Hash[:success => true, :entity => self.get_entity(params)]
    halt 404, JSON.generate({:success => false, 
      :message => "not found"}) if not response[:entity]
    JSON.generate(response)
  end
  
  put '/entity' do
    response = Hash[:success => true, :entity => self.get_entity(params, true)]
    halt 500, JSON.generate({:success => false, 
      :message => "unable to create entity"}) if not response[:entity]
    status 201
    JSON.generate(response)
  end
  
  delete '/entity' do
    response = Hash[:success => true]
    self.delete_entity(params)
    JSON.generate(response)
  end
  
  put '/entity/tags' do
    response = Hash[:success => true, :entity => self.tag_entity(params, true)]
    halt 500, JSON.generate({:success => false, 
      :message => "unable to create entity tag"}) if not response[:entity]
    JSON.generate(response)
  end
  
  delete '/entity/tags' do
    response = Hash[:success => true, :entity => self.tag_entity(params, false)]
    halt 500, JSON.generate({:success => false, 
      :message => "unable to remove entity tag"}) if not response[:entity]
    JSON.generate(response)
  end
  
  get '/entity/similiar' do
    response = Hash[:success => true, :results => self.get_entity_similiar(params)]
    JSON.generate(response)
  end
  
  get '/group' do
    response = Hash[:success => true, 
      :results => self.similiar_entities(params)]
    JSON.generate(response)
  end
  
  post '/group' do
    self.group_entities(params)
    response = Hash[:success => true, 
      :result => self.similiar_entities(params)]
    JSON.generate(response)
  end
end