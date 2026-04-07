# This module provides snapshot/rollback functionality on an object level.
# This is only possible because this app uses a standardized document
# structure--if your model has a more complex structure, you may need to
# implement your own snapshot/rollback logic.
#
# Including this module updates `save` so you likely don't need
# to do anything to take advantage of this.
#
# Example usage:
#
#     class MyModel < ApplicationRecord
#       include CouchDBRollback
#       def my_method
#         snapshot!
#         do_something_risky
#         clear_snapshot!
#       rescue StandardError => e
#         rollback!
#       end
#     end
module CouchDBRollback
  extend ActiveSupport::Concern

  included do
    extend CouchDBRollback::ClassMethods
    enable_rollbacks!
  end

  def snapshot!
    @snapshot = as_json if self.class.rollbacks_enabled?
  end

  def clear_snapshot!
    @snapshot = nil if self.class.rollbacks_enabled?
  end

  # Override `save!` to use snapshot/rollback functionality.
  # Because of how inheritance works this effectively updates
  # `save` and `create` as well
  def save!(**options)
    snapshot!
    super(**options) # Calls ApplicationRecord#save (or ModelSubclass#save if defined)
    clear_snapshot!
    true
  rescue StandardError
    # We may not have gotten far enough to create a snapshot,
    # e.g. if a pre-save hook throws :abort
    rollback! if @snapshot
    raise
  end

  def rollback!
    return unless @snapshot && self.class.rollbacks_enabled?

    update!(@snapshot)
    # Don't clear the snapshot so we can recover it after the rollback/if rollback fails
  end

  class_methods do
    def disable_rollbacks!
      @rollbacks_enabled = false
    end

    def rollbacks_enabled? = @rollbacks_enabled

    def enable_rollbacks!
      @rollbacks_enabled = true
    end
  end
end