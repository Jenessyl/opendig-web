# DSL for defining callbacks in models. Usage:
#
#   class MyModel < ApplicationRecord
#     register_callback :before_some_action
#     register_callback :after_some_action, handler: :my_method
#
#     # Called for each callback registered with `after_some_action`
#     def my_method(&callback)
#       run_code
#       callback.call
#       run_more_code
#     end
#
#     def some_action
#       run_callbacks(:before_some_action)
#       # ... rest of the action code ...
#     end
#   end
#   # In a subclass:
#   class MySubModel < MyModel
#     before_some_action :name_of_method
#     before_some_action do
#       # additional code to run before some action
#     end
#   end
module HasCallbacks
  extend ActiveSupport::Concern

  included do
    class_attribute :_callbacks, instance_accessor: false, default: Hash.new { |h, k| h[k] = [] }
    class_attribute :_callback_handlers, instance_accessor: false, default: {}

    # run_callbacks needs to be an instance method so it will run in instance context
    def run_callbacks(name)
      self.class._callbacks[name].each do |callback|
        handler = self.class._callback_handlers[name]
        if handler.is_a?(Symbol)
          handler = method(handler)
        elsif !handler # No handler defined
          handler = ->(cb) { cb.call }
        end

        if callback.is_a?(Symbol)
          callback = method(callback)
        elsif callback.respond_to?(:call)
          # callback is already a proc/lambda or similar, so we can use it directly
        else
          raise ArgumentError, "Invalid callback: #{callback.inspect}"
        end

        handler.call(&callback)
      end
    end
  end

  class_methods do
    # Registers a callback for the given name. If a handler is given
    # (either as a symbol or a block), it will be called for each
    # callback registered with that name. If no handler is given,
    # callbacks will be called directly.
    #
    # Callbacks for an event can be triggered with `run_callbacks(:name)`.
    #
    # Usage:
    #       register_callback :before_save, handler: :my_handler_method
    #       # Later:
    #       run_callbacks(:before_save)
    def register_callback(name, handler: nil, &handler_block)
      _callbacks[name] ||= []
      _callback_handlers[name] = handler || handler_block if handler || handler_block
      # Define corresponding class method for registering callbacks
      define_singleton_method(name) do |method_name = nil, &block|
        if method_name
          _callbacks[name] << method_name
        elsif block_given?
          _callbacks[name] << block
        else
          raise ArgumentError, "Must provide a method name or a block for #{name} callback"
        end
      end
    end
  end
end
