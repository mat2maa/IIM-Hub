require File.join(File.dirname(__FILE__), 'test_helper.rb')
require File.join(File.dirname(__FILE__), '..', 'lib', 'in_model.rb')

ActiveRecord::Base.send :include, Authorization::AuthorizationInModel
#ActiveRecord::Base.logger = Logger.new(STDOUT)

options = {:adapter => 'sqlite3', :timeout => 500, :database => ':memory:'}
ActiveRecord::Base.establish_connection(options)
ActiveRecord::Base.configurations = { 'sqlite3_ar_integration' => options }
ActiveRecord::Base.connection

File.read(File.dirname(__FILE__) + "/schema.sql").split(';').each do |sql|
  ActiveRecord::Base.connection.execute(sql) unless sql.blank?
end

class TestModel < ActiveRecord::Base
  has_many :test_attrs
  has_many :test_attr_throughs, :through => :test_attrs
  has_many :test_attrs_with_attr, :class_name => "TestAttr", :conditions => {:attr => 1}
  has_many :test_attr_throughs_with_attr, :through => :test_attrs, 
    :class_name => "TestAttrThrough", :source => :test_attr_throughs,
    :conditions => "test_attrs.attr = 1"
  has_one :test_attr_has_one, :class_name => "TestAttr"
  has_one :test_attr_throughs_with_attr_and_has_one, :through => :test_attrs,
    :class_name => "TestAttrThrough", :source => :test_attr_throughs,
    :conditions => "test_attrs.attr = 1"
end

class TestAttr < ActiveRecord::Base
  belongs_to :test_model
  has_many :test_attr_throughs
  attr_reader :roles
  def initialize (*args)
    @roles = []
    super(*args)
  end
end

class TestAttrThrough < ActiveRecord::Base
  belongs_to :test_attr
end

class TestModelSecurityModel < ActiveRecord::Base
  has_many :test_attrs
  using_access_control
end
class TestModelSecurityModelWithFind < ActiveRecord::Base
  set_table_name "test_model_security_models"
  has_many :test_attrs
  using_access_control :include_read => true, 
    :context => :test_model_security_models
end

class ModelTest < Test::Unit::TestCase
  def test_named_scope_with_is
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    TestModel.create!
    
    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id)
    assert_equal 1, TestModel.with_permissions_to(:read, 
      :context => :test_models, :user => user).length
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    assert_raise Authorization::NotAuthorized do
      TestModel.with_permissions_to(:update_test_models, :user => user)
    end
    TestModel.delete_all
  end
  
  def test_named_scope_with_empty_obligations
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    TestModel.create!
    
    user = MockUser.new(:test_role)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    assert_raise Authorization::NotAuthorized do
      TestModel.with_permissions_to(:update, :user => user)
    end
    TestModel.delete_all
  end
  
  def test_named_scope_multiple_obligations
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value }
          end
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value_2 }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    
    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id, 
                        :test_attr_value_2 => test_model_2.id)
    assert_equal 2, TestModel.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
  end
  
  def test_named_scope_multiple_and_empty_obligations
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value }
          end
          has_permission_on :test_models, :to => :read
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    TestModel.create!
    
    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id)
    assert_equal 2, TestModel.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
  end
  
  def test_named_scope_multiple_attributes
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value }, :content => "bla"
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create! :content => 'bla'
    TestModel.create! :content => 'bla'
    TestModel.create!
    
    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
  end
  
  def test_named_scope_with_is_and_priv_hierarchy
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      privileges do
        privilege :read do
          includes :list, :show
        end
      end
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    TestModel.create!
    
    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id)
    assert_equal 1, TestModel.with_permissions_to(:list, 
      :context => :test_models, :user => user).length
    assert_equal 1, TestModel.with_permissions_to(:list, :user => user).length
    
    TestModel.delete_all
  end
  
  def test_named_scope_with_is_and_belongs_to
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_model => is { user.test_model }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    test_model_1.test_attrs.create!
    TestModel.create!.test_attrs.create!
    
    user = MockUser.new(:test_role, :test_model => test_model_1)
    assert_equal 1, TestAttr.with_permissions_to(:read, 
      :context => :test_attrs, :user => user).length
    
    TestModel.delete_all
    TestAttr.delete_all
  end
  
  def test_named_scope_with_deep_attribute
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_model => {:id => is { user.test_model_id } }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    test_model_1.test_attrs.create!
    TestModel.create!.test_attrs.create!
    
    user = MockUser.new(:test_role, :test_model_id => test_model_1.id)
    assert_equal 1, TestAttr.with_permissions_to(:read, 
      :context => :test_attrs, :user => user).length
    
    TestModel.delete_all
    TestAttr.delete_all
  end
  
  def test_named_scope_with_contains
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attrs => contains { user }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_model_1.test_attrs.create!
    test_model_1.test_attrs.create!
    test_model_2.test_attrs.create!
    
    user = MockUser.new(:test_role,
                        :id => test_model_1.test_attrs.first.id)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).find(:all, :conditions => {:id => test_model_1.id}).length
    
    TestModel.delete_all
    TestAttr.delete_all
  end
  
  def test_named_scope_with_contains_conditions
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attrs_with_attr => contains { user }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_model_1.test_attrs_with_attr.create!
    test_model_1.test_attrs.create!(:attr => 2)
    test_model_2.test_attrs_with_attr.create!
    test_model_2.test_attrs.create!(:attr => 2)
    
    #assert_equal 1, test_model_1.test_attrs_with_attr.length
    user = MockUser.new(:test_role,
                        :id => test_model_1.test_attrs.first.id)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    user = MockUser.new(:test_role,
                        :id => test_model_1.test_attrs.last.id)
    assert_equal 0, TestModel.with_permissions_to(:read, :user => user).length
        
    TestModel.delete_all
    TestAttr.delete_all
  end
  
  def test_named_scope_with_contains_through_conditions
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attr_throughs_with_attr => contains { user }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_model_1.test_attrs.create!(:attr => 1).test_attr_throughs.create!
    test_model_1.test_attrs.create!(:attr => 2).test_attr_throughs.create!
    test_model_2.test_attrs.create!(:attr => 1).test_attr_throughs.create!
    test_model_2.test_attrs.create!(:attr => 2).test_attr_throughs.create!
    
    #assert_equal 1, test_model_1.test_attrs_with_attr.length
    user = MockUser.new(:test_role,
                        :id => test_model_1.test_attr_throughs.first.id)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    user = MockUser.new(:test_role,
                        :id => test_model_1.test_attr_throughs.last.id)
    assert_equal 0, TestModel.with_permissions_to(:read, :user => user).length

    TestModel.delete_all
    TestAttrThrough.delete_all
    TestAttr.delete_all
  end
  
  def test_named_scope_with_is_and_has_one
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do :test_attr_has_one
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attr_has_one => is { user.test_attr }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    test_attr_1 = test_model_1.test_attrs.create!
    TestModel.create!.test_attrs.create!
    
    user = MockUser.new(:test_role, :test_attr => test_attr_1)
    assert_equal 1, TestModel.with_permissions_to(:read, 
      :context => :test_models, :user => user).length
    
    TestModel.delete_all
    TestAttr.delete_all
  end
  
  def test_named_scope_with_is_and_has_one_through_conditions
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attr_throughs_with_attr_and_has_one => contains { user }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_model_1.test_attrs.create!(:attr => 1).test_attr_throughs.create!
    test_model_1.test_attrs.create!(:attr => 2).test_attr_throughs.create!
    test_model_2.test_attrs.create!(:attr => 1).test_attr_throughs.create!
    test_model_2.test_attrs.create!(:attr => 2).test_attr_throughs.create!
    
    #assert_equal 1, test_model_1.test_attrs_with_attr.length
    user = MockUser.new(:test_role,
                        :id => test_model_1.test_attr_throughs.first.id)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    user = MockUser.new(:test_role,
                        :id => test_model_1.test_attr_throughs.last.id)
    assert_equal 0, TestModel.with_permissions_to(:read, :user => user).length
           
    TestModel.delete_all
    TestAttr.delete_all
  end
  
  def test_named_scope_with_is_in
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_model => is_in { [user.test_model, user.test_model_2] }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_model_1.test_attrs.create!
    TestModel.create!.test_attrs.create!
    
    user = MockUser.new(:test_role, :test_model => test_model_1,
      :test_model_2 => test_model_2)
    assert_equal 1, TestAttr.with_permissions_to(:read, 
      :context => :test_attrs, :user => user).length
    
    TestModel.delete_all
    TestAttr.delete_all
  end
  
  def test_model_security
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role_unrestricted do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
          end
        end
        role :test_role do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
            if_attribute :attr => is { 1 }
          end
        end
        role :test_role_restricted do
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    Authorization.current_user = MockUser.new(:test_role)
    assert(object = TestModelSecurityModel.create)
    Authorization.current_user = MockUser.new(:test_role_restricted)
    assert_raise Authorization::NotAuthorized do
      object.update_attributes(:attr_2 => 2)
    end
    Authorization.current_user = MockUser.new(:test_role)
    assert_nothing_raised { object.update_attributes(:attr_2 => 2) }
    object.reload
    assert_equal 2, object.attr_2 
    object.destroy
    assert_raise ActiveRecord::RecordNotFound do
      TestModelSecurityModel.find(object.id)
    end
    
    assert_raise Authorization::AttributeAuthorizationError do
      TestModelSecurityModel.create :attr => 2
    end
    object = TestModelSecurityModel.create
    assert_raise Authorization::AttributeAuthorizationError do
      object.update_attributes(:attr => 2)
    end
    Authorization.current_user = MockUser.new(:test_role_unrestricted)
    object = TestModelSecurityModel.create :attr => 2
    object_with_find = TestModelSecurityModelWithFind.create :attr => 2
    Authorization.current_user = MockUser.new(:test_role)
    assert_nothing_raised do
      object.class.find(object.id)
    end
    assert_raise Authorization::AttributeAuthorizationError do
      object_with_find.class.find(object_with_find.id)
    end
    assert_raise Authorization::AttributeAuthorizationError do
      object.update_attributes(:attr_2 => 2)
    end
    # TODO test this:
    #assert_raise Authorization::AuthorizationError do
    #  object.update_attributes(:attr => 1)
    #end
    assert_raise Authorization::AttributeAuthorizationError do
      object.destroy
    end
    
    Authorization.current_user = MockUser.new(:test_role_2)
    assert_raise Authorization::NotAuthorized do
      TestModelSecurityModel.create
    end
  end
  
  def test_model_security_with_assoc
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_model_security_models do
            to :create, :update, :delete
            if_attribute :test_attrs => contains { user }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_attr = TestAttr.create
    test_attr.roles << :test_role
    Authorization.current_user = test_attr
    assert(object = TestModelSecurityModel.create(:test_attrs => [test_attr]))
    assert_nothing_raised do
      object.update_attributes(:attr_2 => 2)
    end
    object.reload
    assert_equal 2, object.attr_2 
    object.destroy
    assert_raise ActiveRecord::RecordNotFound do
      TestModelSecurityModel.find(object.id)
    end
  end
end
