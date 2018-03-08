require 'rubygems'
require 'sinatra/base'
require 'rugroupy'
require 'rugroupy/mongo'
require 'json'

# Run the server like this by extending GroupyServer and calling run!
# require 'rugroupy/server'
# class MyApp < Groupy::GroupyServer
#   register Sinatra::MongoExtension
#   set :mongo, 'mongodb://localhost:27017/test'
#   optionally set more things (port, etc.) according to http://www.sinatrarb.com/configuration.html
# end
# MyApp.run!

module Groupy
  module GroupyServerSupport
    def get_entity(params, create = false)
      e_json = get_entity_json(params)
      e = Groupy::Entity.new(mongo, e_json['name'], e_json['id'], create)
      e.get
    end

    def get_entity_json(params)
      JSON.parse(params[:entity])
    end

    def get_entity_similiar(params)
      e_json = get_entity_json(params)
      e = Groupy::Entity.new(mongo, e_json['name'], e_json['id'], create = false)
      e.similiar(e_json['tag'], e_json['skip'], e_json['limit'], e_json['reverse'])
    end

    def delete_entity(params)
      e_json = get_entity_json(params)
      e = Groupy::Entity.new(mongo, e_json['name'], e_json['id'], create = create)
      e.delete
    end

    def tag_entity(params, create = true)
      e_json = get_entity_json(params)
      e = Groupy::Entity.new(mongo, e_json['name'], e_json['id'], create = create)
      e_json['tags'].each_pair do |name, value|
        create ? e.tag(name, value) : e.untag(name, value)
      end
      e.get
    end

    def group_entities(params)
      e_json = get_entity_json(params)
      g = Groupy::EntityGrouper.new(mongo, e_json['name'])
      options = { includeFunction: e_json['include_function'],
                  scoreFunction: e_json['score_function'],
                  dynamicTagFunction: e_json['dynamic_tag_function'] }
      g.group(options)
    end

    def similiar_entities(params)
      e_json = get_entity_json(params)
      g = Groupy::EntityGrouper.new(mongo, e_json['name'])
      g.similiar(e_json['tag'], e_json['skip'], e_json['limit'], e_json['reverse'])
    end
  end

  class GroupyServer < Sinatra::Base
    include GroupyServerSupport
    # register Groupy::MongoExtension
    # set :mongo, 'mongo://localhost:27017/test'

    before do
      headers 'Content-Type' => 'application/json; charset=UTF-8'
    end

    get '/entity' do
      response = Hash[success: true, entity: get_entity(params)]
      unless response[:entity]
        halt 404, JSON.generate(success: false,
                                message: 'not found')
      end
      JSON.generate(response)
    end

    put '/entity' do
      response = Hash[success: true, entity: get_entity(params, true)]
      unless response[:entity]
        halt 500, JSON.generate(success: false,
                                message: 'unable to create entity')
      end
      status 201
      JSON.generate(response)
    end

    delete '/entity' do
      response = Hash[success: true]
      delete_entity(params)
      JSON.generate(response)
    end

    put '/entity/tags' do
      response = Hash[success: true, entity: tag_entity(params, true)]
      unless response[:entity]
        halt 500, JSON.generate(success: false,
                                message: 'unable to create entity tag')
      end
      JSON.generate(response)
    end

    delete '/entity/tags' do
      response = Hash[success: true, entity: tag_entity(params, false)]
      unless response[:entity]
        halt 500, JSON.generate(success: false,
                                message: 'unable to remove entity tag')
      end
      JSON.generate(response)
    end

    get '/entity/similiar' do
      response = Hash[success: true, results: get_entity_similiar(params)]
      JSON.generate(response)
    end

    get '/group' do
      response = Hash[success: true,
                      results: similiar_entities(params)]
      JSON.generate(response)
    end

    post '/group' do
      group_entities(params)
      response = Hash[success: true,
                      result: similiar_entities(params)]
      JSON.generate(response)
    end
  end
end
