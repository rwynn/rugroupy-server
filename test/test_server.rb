require 'helper'

class GroupServer
  include HTTParty
  base_uri 'http://localhost:4567'
end

module TestHelpers
  def assert_content_type_json(response)
    assert_equal 'application/json; charset=UTF-8', response.headers['Content-Type']
  end

  def assert_response_with_code(response, code)
    puts response.body
    assert response != nil
    assert_equal code, response.code
    assert_content_type_json(response)
  end

  def create_entity(entity_id)
    json = JSON.generate(name: 'users', id: entity_id)
    response = GroupServer.put('/entity', body: { entity: json })
    assert_response_with_code(response, 201)
    response_body_json = JSON.parse(response.body)
    assert response_body_json['success']
  end

  def tag_entity(entity_id, tags)
    json = JSON.generate(name: 'users', id: entity_id, tags: tags)
    response = GroupServer.put('/entity/tags', body: { entity: json })
    assert_response_with_code(response, 200)
    response_body_json = JSON.parse(response.body)
    assert response_body_json['success']
    response_tags = response_body_json['entity']['tags']
    tags.each_pair do |name, value|
      if value.is_a?(String)
        assert response_tags[name.to_s].member?(value)
      else
        value.each do |v|
          assert response_tags[name.to_s].member?(v)
        end
      end
    end
  end

  def untag_entity(entity_id, tags)
    json = JSON.generate(name: 'users', id: entity_id, tags: tags)
    response = GroupServer.delete('/entity/tags', body: { entity: json })
    assert_response_with_code(response, 200)
    response_body_json = JSON.parse(response.body)
    assert response_body_json['success']
    response_tags = response_body_json['entity']['tags']
    tags.each_pair do |name, value|
      if value.is_a?(String)
        assert response_tags[name.to_s].member?(value) == false
      else
        value.each do |v|
          assert response_tags[name_to.s].member?(v) == false
        end
      end
    end
  end

  def group_entities(options = {})
    options[:name] = 'users'
    json = JSON.generate(options)
    response = GroupServer.post('/group', body: { entity: json })
    assert_response_with_code(response, 200)
    response_body_json = JSON.parse(response.body)
    assert response_body_json['success']
  end

  def get_similiar
    json = JSON.generate(name: 'users')
    response = GroupServer.get('/group', body: { entity: json })
    assert_response_with_code(response, 200)
    response_body_json = JSON.parse(response.body)
    assert response_body_json['success']
    response_body_json['results']
  end

  def get_similiar_to(entity_id)
    json = JSON.generate(name: 'users', id: entity_id)
    response = GroupServer.get('/entity/similiar', body: { entity: json })
    assert_response_with_code(response, 200)
    response_body_json = JSON.parse(response.body)
    assert response_body_json['success']
    response_body_json['results']
  end
end

module Minitest
  class Test
    include TestHelpers
  end
end

class TestServer < MiniTest::Test
  describe 'a groupy server' do
    before do
      @database_name = 'test'
      @connection =  Mongo::Client.new('mongodb://localhost')
      @database = Mongo::Database.new(@connection, @database_name)
      @entity_name = 'users'
      @user_json = JSON.generate(name: 'users', id: 'user1')
      @user_json_tagged = JSON.generate(name: 'users', id: 'user1', tags: { likes: 'mongodb' })
      @entity_ids = %w[user1 user2 user3 user4]
      @entities = @entity_ids.collect do |n|
        Groupy::Entity.new(@database, @entity_name, n, false)
      end
    end

    after do
      @database[@entity_name].drop
      @database["#{@entity_name}_invert"].drop
      @database["#{@entity_name}_count"].drop
      @database.drop
      @connection.close
    end

    describe 'find similiar entities' do
      it do
        # create some entities
        create_entity('user1')
        create_entity('user2')
        create_entity('user3')

        # apply some tags
        tag_entity('user1', likes: 'mongodb')
        tag_entity('user2', likes: 'apache')
        tag_entity('user3', likes: 'mongodb')

        group_entities

        # test similiarity across all
        results = get_similiar

        assert results != nil
        assert_equal 1, results.size
        assert results[0].member?('user1')
        assert results[0].member?('user3')
      end
    end

    describe 'find entities similiar to a specific entity' do
      it do
        # create some entities
        create_entity('user1')
        create_entity('user2')
        create_entity('user3')

        # apply some tags
        tag_entity('user1', likes: 'mongodb')
        tag_entity('user2', likes: 'apache')
        tag_entity('user3', likes: 'mongodb')

        group_entities

        # test similiarity to specific entity
        results = get_similiar_to('user3')

        assert results != nil
        assert_equal 1, results.size
        assert results.member?('user1')
      end
    end

    describe 'group entitites with custom scoring' do
      it do
        # create some entities
        create_entity('user1')
        create_entity('user2')
        create_entity('user3')

        # apply some tags
        tag_entity('user1', likes: %w[x y z], wants: ['a'])
        tag_entity('user2', likes: %w[x z], wants: %w[a b c])
        tag_entity('user3', likes: ['x'], wants: %w[b c])

        # group entities with a custom score function
        group_entities(score_function: "function(tag) { if (tag == 'wants') return 3; else return 1; }")

        # test similiarity to specific entity
        results = get_similiar_to('user2')

        assert results != nil
        assert_equal 2, results.size
        assert_equal 'user3', results[0]
        assert_equal 'user1', results[1]
      end
    end

    describe 'group entities with custom tag inclusion' do
      it do
        # create some entities
        create_entity('user1')
        create_entity('user2')
        create_entity('user3')

        # apply some tags
        tag_entity('user1', likes: %w[x y z], wants: ['a'])
        tag_entity('user2', likes: %w[x z], wants: %w[a b c])
        tag_entity('user3', likes: ['x'], wants: %w[b c])

        # group entities with a custom include function
        group_entities(include_function: "function(tag) { return (tag == 'likes'); }")

        # test similiarity to specific entity
        results = get_similiar_to('user2')

        assert results != nil
        assert_equal 2, results.size
        assert_equal 'user1', results[0]
        assert_equal 'user3', results[1]
      end
    end

    describe 'group entities with dynamically generated tags' do
      it do
        dynamicTagFunction = <<-EOF
         function (doc) {
           doc_id = doc._id;
           for (tag in doc.tags) {
             if (tag == 'zipcode') {
               doc.tags[tag].forEach(function(a) {
                   if (parseInt(a) >= 22204 && parseInt(a) <= 22207) {
                       emit({tag:"arlington", value:true}, {entities: [doc_id]});
                   }
               });
             }
           }
         }
        EOF
        # apply some tags
        tag_entity('user1', likes: ['x'], wants: ['a'], zipcode: ['22207'])
        tag_entity('user2', likes: ['x'], wants: ['a'], zipcode: ['90210'])
        tag_entity('user3', likes: ['x'], wants: ['a'], zipcode: ['22204'])

        # group entities with a dynamic tag function
        group_entities(dynamic_tag_function: dynamicTagFunction)

        # test similiarity to specific entity
        results = get_similiar_to('user1')

        assert results != nil
        assert_equal 2, results.size
        assert_equal 'user3', results[0]
        assert_equal 'user2', results[1]
      end
    end

    describe 'delete entities' do
      it do
        # create an entity
        create_entity('user1')
        response = GroupServer.delete('/entity', body: { entity: @user_json })
        assert_response_with_code(response, 200)
        response_body_json = JSON.parse(response.body)
        assert response_body_json['success']
        assert_nil @entities[0].get
      end
    end

    describe 'retrieve entities' do
      it do
        # create an entity
        create_entity('user1')
        # retrieve that entity
        response = GroupServer.get('/entity', body: { entity: @user_json })
        assert_response_with_code(response, 200)
        response_body_json = JSON.parse(response.body)
        assert response_body_json['success']
        assert_equal 'user1', response_body_json['entity']['_id']
      end
    end

    describe 'respond to missing entities' do
      it do
        # retrieve an entity that does not exist
        response = GroupServer.get('/entity', body: { entity: @user_json })
        assert_response_with_code(response, 404)
        response_body_json = JSON.parse(response.body)
        assert response_body_json['success'] == false
      end
    end

    describe 'create entities' do
      it do
        # create an entity
        create_entity('user1')
      end
    end

    describe 'tag entities' do
      it do
        # create an entity
        create_entity('user1')
        # apply an entity tag
        tag_entity('user1', likes: 'mongodb')
      end
    end

    describe 'untag entities' do
      it do
        # create an entity
        create_entity('user1')
        # apply an entity tag
        tag_entity('user1', likes: 'mongodb')
        # remove the entity tag
        untag_entity('user1', likes: 'mongodb')
      end
    end
  end
end
