# Normally, ApplicationRecord inherits from ActiveRecord::Base, but this app is backed by CouchDB.
# This is instead a custom superclass to handle connection to CouchDB, provide functionality such as
# validations and other features normally found in ActiveRecord, and to serve as a base class for all
# models in the application.
#
# To use this class, your model may need to override the default definitions of `@collection_name`,
# `to_document`, `Model.from_document`, and `Model.all_documents`. You may additionally want to use
# the `before_save`, `after_save`, `before_destroy`, and `after_destroy` callbacks. Use `throw(:abort)`
# in a before callback to cancel the save/destroy action. See the example usage below for more details.
#
# Example usage:
#
#     class MyModel < ApplicationRecord
#       attr_accessor :field1, :field2
#
#       disable_rollbacks! # Enabled by default
#
#       before_save { throw(:abort) if some_condition }
#       after_save :do_something
#
#       validates :attr, uniqueness: { scope: :other_attr }
#
#       # Optional. Defaults e.g. `CustomResource` => `opendig/custom_resources`
#       collection_name 'opendig/my_models'
#
#       # Define `to_document` if `as_json` doesn't work for your model's structure
#       def to_document
#         {
#           field1: field1,
#           field2: field2,
#           custom_field: 'something else'
#         }
#       end
#
#       # Define `from_document` if your model has a nonstandard structure
#       def self.from_document(doc)
#         data = do_something_with(doc)
#         new(**data)
#       end
#
#       # Define `all_documents` if you need to customize how documents are retrieved from CouchDB
#       def self.all_documents
#         # Use `db` to access CouchDB directly
#         db.view(collection_name, {option_one: 'value'}).map { |row| row['value'] }
#       end
#     end
class ApplicationRecord

  # Submodules

  class Error < StandardError
    attr_reader :record

    def initialize(record, message)
      @record = record
      super(message)
    end

    def self.abort_handler(&block)
      lambda do
        catch(:abort) do
          block.call
          next
        end
        # If we got here, block threw :abort
        raise new(nil)
      end
    end

    class RecordInvalid < Error
      def initialize(record)
        super(record, "Validation failed: #{record.errors.full_messages.join(', ')}")
      end
    end

    class RecordNotSaved < Error
      def initialize(record)
        super(record, "Failed to save record: #{record.inspect}")
      end
    end

    class RecordNotDestroyed < Error
      def initialize(record)
        super(record, "Failed to destroy record: #{record.inspect}")
      end
    end

    class RecordNotFound < Error
      def initialize(klass, query)
        super(nil, "Couldn't find #{klass.name} with #{query.map { |k, v| "#{k}: #{v}" }.join(', ')}")
      end
    end
  end

  module ClassMethods
    # Default collection name, e.g. `MyModel` => `opendig/my_models`
    def collection_name(name = nil)
      if name
        @collection_name = name
      else
        @collection_name ||= "opendig/#{subclass.name.tableize}"
      end
    end

    def db = Rails.application.config.couchdb

    def all_documents
      db.view(@collection_name)['rows']&.map { |row| row['value'] } || []
    end

    def all(in_memory: true)
      if in_memory
        @instances = all_documents.map { |doc| from_document(doc) } if @instances.blank?
        @instances
      else
        all_documents.map { |doc| from_document(doc) }
      end
    end

    def find_by(**query)
      where(**query).first
    end

    def find_by!(**query)
      find_by(**query) || (raise Error::RecordNotFound.new(self, query))
    end

    def find_or_create_by(**query)
      find_by(**query) || create(**query)
    end

    def where(**query)
      all.select do |instance|
        query.all? { |key, value| instance.send(key) == value }
      end
    end

    def from_document(doc)
      @rewritten_attributes.each do |model_attr, document_key|
        doc[model_attr.to_s] = doc.delete(document_key) || ""
      end
      @ignored_attributes[:couchdb].each do |document_key|
        doc.delete(document_key)
      end
      new(doc)
    end

    def create(...)
      record = new(...)
      record.save
      record
    end

    def create!(...)
      record = new(...)
      record.save!
      record
    end

    def reload_instances!
      # The first time this method is called, @instances is undefined.
      # In this case we want to skip straight to the last line.
      # After that, we need to check if any instances are not persisted
      # and persist them before reloading from the database to prevent
      # desyncs.
      @instances&.each do |instance|
        instance.save! unless instance.persisted?
      end

      @instances = all(in_memory: false)
    end

    # Some attributes may have different keys in CouchDB vs in the model.
    # You can indicate these by using this method in your model.
    #
    # Example usage:
    #
    #       class MyModel < ApplicationRecord
    #         rewrite_attribute :model_attr, 'document_key'
    #       end
    #       my_model = MyModel.new(model_attr: 'value')
    #       my_model.save! # CouchDB: { 'document_key' => 'value' }
    def rewrite_attribute(model_attr, document_key)
      @rewritten_attributes[model_attr.to_s] = document_key.to_s
    end

    # Some attributes may show up in the model or in CouchDB but not both.
    # You can indicate these by using this method in your model. `model`
    # is for attributes that show up in the model but not in CouchDB, and
    # `couchdb` is for attributes that show up in CouchDB but not the model.
    def ignore_attribute(model: nil, couchdb: nil)
      @ignored_attributes[:model] << model.to_s if model
      @ignored_attributes[:couchdb] << couchdb.to_s if couchdb
    end

    # We extend attr_writer and attr_accessor to keep @persisted up to date
    def attr_writer(*attrs)
      super(*attrs)
      attrs.each do |attr|
        define_method("#{attr}=") do |value|
          instance_variable_set("@#{attr}", value)
          @persisted = false
        end
      end
    end

    # We extend attr_writer and attr_accessor to keep @persisted up to date
    def attr_accessor(*attrs)
      super(*attrs)
      attr_writer(*attrs)
    end

    def instances
      @instances ||= []
    end

    attr_reader :rewritten_attributes, :ignored_attributes
  end

  include ActiveModel::Model
  include ActiveModel::Attributes
  include HasCallbacks
  include CouchDBRollback

  # Default attributes
  attr_accessor :id, :rev

  # Whether or not the record in memory agrees with the record in CouchDB
  def persisted? = @persisted

  def self.inherited(subclass)
    super
    subclass.extend(ClassMethods)

    # Attribute helpers
    subclass.instance_variable_set(:@rewritten_attributes, {})
    subclass.instance_variable_set(:@ignored_attributes, { model: [], couchdb: [] })

    # Default CouchDB attribute compatibility
    subclass.rewrite_attribute(:id, '_id')
    subclass.rewrite_attribute(:rev, '_rev')
    subclass.ignore_attribute model: 'persisted'
    subclass.ignore_attribute model: 'validation_context'
    subclass.ignore_attribute model: 'errors'

    # In-memory store for instances
    subclass.reload_instances!
  end

  # Model.new does not save to the database
  def initialize(...)
    super(...)
    validate!
    @persisted = false
    self.class.instances << self
  end

  def destroy
    run_callbacks(:before_destroy)
    @persisted = false
    # TODO: implement removing from CouchDB
    self.class.instances.delete(self)
    run_callbacks(:after_destroy)
    freeze # Return frozen instance
  rescue StandardError
    false
  end

  def destroy!
    destroy || (raise Error::RecordNotDestroyed.new(self)) # rubocop:disable Style/RaiseArgs
  end

  def to_document
    as_json
  end

  def update(attributes)
    update!(attributes)
  rescue Error::RecordInvalid, Error::RecordNotSaved
    false
  end

  def update!(attributes)
    @persisted = false
    attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
    validate!
    save!
  end

  def save(**options)
    save!(**options)
  # Other error types are probably not recoverable
  rescue Error::RecordInvalid, Error::RecordNotSaved
    false
  end

  def save!(validate: true)
    # unless save(**options)
    #   error_class = errors.any? ? Error::RecordInvalid : Error::RecordNotSaved
    #   raise error_class.new(self)
    # end

    # true

    raise Error::RecordInvalid.new(self) if validate && !valid? # Short-circuit so checks don't run with `save(validate: false)` # rubocop:disable Style/RaiseArgs

    run_callbacks(:before_save)
    doc = to_document

    self.class.rewritten_attributes.each do |model_attr, document_key|
      doc[document_key] = doc.delete(model_attr.to_s) || ""
    end
    # Ignore model-specific attributes that shouldn't be in CouchDB
    # Since this is a one-way operation (model -> CouchDB), we only
    # need to worry about model-only attributes, not CouchDB-only
    self.class.ignored_attributes[:model].each do |document_key|
      doc.delete(document_key)
    end

    begin
      db.save_doc(doc)
      # CouchDB returns the new revision in the response to a successful save.
      # The Ruby bindings update the document in-place with the new revision,
      # so we can just read it back out.
      @rev = doc['_rev']
      @persisted = true
    rescue StandardError => e
      raise Error::RecordNotSaved.new(self) # rubocop:disable Style/RaiseArgs
    end

    run_callbacks(:after_save)
    true
  end

  def reload_instance!
    document = self.class.all_documents.find { |doc| doc['_id'] == id }
    raise Error::RecordNotFound.new(self.class, id: id) unless document

    update(document)
    @persisted = true
  end

  # Instances can just use `self.db` to access the database
  def db = Rails.application.config.couchdb

  register_callback :before_save, handler: Error::RecordNotSaved.abort_handler
  register_callback :after_save
  register_callback :before_destroy, handler: Error::RecordNotDestroyed.abort_handler
  register_callback :after_destroy
end
