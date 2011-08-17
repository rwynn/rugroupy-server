require 'helper'

class GroupServer
  include HTTParty
  base_uri 'http://localhost:4567'
end

module TestHelpers
  def assert_content_type_json(response)
    assert_equal "application/json; charset=UTF-8", response.headers["Content-Type"]
  end
  
  def assert_response_with_code(response, code)
    assert_not_nil response
    assert_equal code, response.code
    assert_content_type_json(response)
  end

  def create_entity(entity_id)
    json = JSON.generate({:name => "users", :id => entity_id})
    response = GroupServer.put("/entity", {:body => {:entity => json }})
    self.assert_response_with_code(response, 201)
    response_body_json = JSON.parse(response.body)
    assert response_body_json["success"]
  end

  def tag_entity(entity_id, tags)
    json = JSON.generate({:name => "users", :id => entity_id, :tags => tags })
    response = GroupServer.put("/entity/tags", {:body => {:entity => json }})
    self.assert_response_with_code(response, 200)
    response_body_json = JSON.parse(response.body)
    assert response_body_json["success"]
    response_tags = response_body_json["entity"]["tags"]
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
    json = JSON.generate({:name => "users", :id => entity_id, :tags => tags })
    response = GroupServer.delete("/entity/tags", {:body => {:entity => json }})
    self.assert_response_with_code(response, 200)
    response_body_json = JSON.parse(response.body)
    assert response_body_json["success"]
    response_tags = response_body_json["entity"]["tags"]
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

  def group_entities(options={})
    options[:name] = "users"
    json = JSON.generate(options)
    response = GroupServer.post("/group", {:body => {:entity => json }})
    self.assert_response_with_code(response, 200)
    response_body_json = JSON.parse(response.body)
    assert response_body_json["success"]
  end

  def get_similiar
    json = JSON.generate({:name => "users"})
    response = GroupServer.get("/group", {:body => {:entity => json }})
    self.assert_response_with_code(response, 200)
    response_body_json = JSON.parse(response.body)
    assert response_body_json["success"]
    response_body_json["results"]
  end

  def get_similiar_to(entity_id)
    json = JSON.generate({:name => "users", :id => entity_id })
    response = GroupServer.get("/entity/similiar", {:body => {:entity => json }})
    self.assert_response_with_code(response, 200)
    response_body_json = JSON.parse(response.body)
    assert response_body_json["success"]
    response_body_json["results"]
  end
end

class TestServer < Test::Unit::TestCase
  include TestHelpers
  context "a groupy server" do
      setup do
        @database_name = "test"
        @connection =  Mongo::Connection.new
        @entity_name = "users"
        @user_json = JSON.generate({:name => "users", :id => "user1"})
        @user_json_tagged = JSON.generate({:name => "users", :id => "user1", :tags => { :likes => "mongodb"}})
        @entity_ids = %w{user1 user2 user3 user4}
        @entities = @entity_ids.collect do |n|
          Groupy::Entity.new(@connection[@database_name], @entity_name, n, false)
        end
      end

      teardown do
        @connection[@database_name][@entity_name].drop()
        @connection[@database_name]["#{@entity_name}_invert"].drop()
        @connection[@database_name]["#{@entity_name}_count"].drop()
        @connection.drop_database(@database_name)
        @connection.close
      end

      should "find similiar entities" do
        # create some entities
        self.create_entity("user1")
        self.create_entity("user2")
        self.create_entity("user3")

        # apply some tags
        self.tag_entity("user1", {:likes => "mongodb" })
        self.tag_entity("user2", {:likes => "apache" })
        self.tag_entity("user3", {:likes => "mongodb" })

        self.group_entities

        # test similiarity across all
        results = self.get_similiar

        assert_not_nil results
        assert_equal 1, results.size
        assert results[0].member?("user1")
        assert results[0].member?("user3")
      end

      should "find entities similiar to a specific entity" do
        # create some entities
        self.create_entity("user1")
        self.create_entity("user2")
        self.create_entity("user3")

        # apply some tags
        self.tag_entity("user1", {:likes => "mongodb" })
        self.tag_entity("user2", {:likes => "apache" })
        self.tag_entity("user3", {:likes => "mongodb" })

        self.group_entities

        # test similiarity to specific entity
        results = self.get_similiar_to("user3")

        assert_not_nil results
        assert_equal 1, results.size
        assert results.member?("user1")
      end


      should "group entitites with custom scoring" do
        # create some entities
        self.create_entity("user1")
        self.create_entity("user2")
        self.create_entity("user3")

        # apply some tags
        self.tag_entity("user1", {:likes => ["x", "y", "z"], :wants => ["a"] })
        self.tag_entity("user2", {:likes => ["x", "z"], :wants => ["a", "b", "c"] })
        self.tag_entity("user3", {:likes => ["x"], :wants => ["b", "c"] })

        # group entities with a custom score function
        self.group_entities(:score_function => "function(tag) { if (tag == 'wants') return 3; else return 1; }")

        # test similiarity to specific entity
        results = self.get_similiar_to("user2")

        assert_not_nil results
        assert_equal 2, results.size
        assert_equal "user3", results[0]
        assert_equal "user1", results[1]
      end

      should "group entities with custom tag inclusion" do
        # create some entities
        self.create_entity("user1")
        self.create_entity("user2")
        self.create_entity("user3")

        # apply some tags
        self.tag_entity("user1", {:likes => ["x", "y", "z"], :wants => ["a"] })
        self.tag_entity("user2", {:likes => ["x", "z"], :wants => ["a", "b", "c"] })
        self.tag_entity("user3", {:likes => ["x"], :wants => ["b", "c"] })

        # group entities with a custom include function
        self.group_entities(:include_function => "function(tag) { return (tag == 'likes'); }")

        # test similiarity to specific entity
        results = self.get_similiar_to("user2")

        assert_not_nil results
        assert_equal 2, results.size
        assert_equal "user1", results[0]
        assert_equal "user3", results[1]
      end

      should "group entities with dynamically generated tags" do
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
        self.tag_entity("user1", {:likes => ["x"], :wants => ["a"], :zipcode => ["22207"] })
        self.tag_entity("user2", {:likes => ["x"], :wants => ["a"], :zipcode => ["90210"] })
        self.tag_entity("user3", {:likes => ["x"], :wants => ["a"], :zipcode => ["22204"] })

        # group entities with a dynamic tag function
        self.group_entities(:dynamic_tag_function => dynamicTagFunction)

        # test similiarity to specific entity
        results = self.get_similiar_to("user1")

        assert_not_nil results
        assert_equal 2, results.size
        assert_equal "user3", results[0]
        assert_equal "user2", results[1]
      end

      should "delete entities" do
        # create an entity
        self.create_entity("user1")
        response = GroupServer.delete("/entity", {:body => {:entity => @user_json }})
        self.assert_response_with_code(response, 200)
        response_body_json = JSON.parse(response.body)
        assert response_body_json["success"]
        assert_nil @entities[0].get()
      end

      should "retrieve entities" do
        # create an entity
        self.create_entity("user1")
        # retrieve that entity
        response = GroupServer.get("/entity", {:body => {:entity => @user_json }})
        self.assert_response_with_code(response, 200)
        response_body_json = JSON.parse(response.body)
        assert response_body_json["success"]
        assert_equal "user1", response_body_json["entity"]["_id"]
      end

      should "respond to missing entities" do
        # retrieve an entity that does not exist
        response = GroupServer.get("/entity", {:body => {:entity => @user_json }})
        self.assert_response_with_code(response, 404)
        response_body_json = JSON.parse(response.body)
        assert response_body_json["success"] == false
      end

      should "create entities" do
        # create an entity
        self.create_entity("user1")
      end

      should "tag entities" do
        # create an entity
        self.create_entity("user1")
        # apply an entity tag
        self.tag_entity("user1", {:likes=>"mongodb"})
      end

      should "untag entities" do
        # create an entity
        self.create_entity("user1")
        # apply an entity tag
        self.tag_entity("user1", {:likes=>"mongodb"})
        # remove the entity tag
        self.untag_entity("user1", {:likes=>"mongodb"})
      end
  end
  
end
