class UniquenessValidator < ActiveModel::EachValidator
  # At most one record should exist with the same value for the specified attribute(s).
  #
  # Due to how ApplicationRecord is set up, this is only ever called after find_by
  # can see the current instance.
  def validate_each(record, attribute, value)
    unique_attributes = options[:scope] ? Array(options[:scope]) : []
    unique_attributes.map! { |attr| [attr, record.send(attr)] }
    unique_attributes << [attribute, value]

    return unless record.class.find_by(**unique_attributes.to_h).size > 1

    record.errors.add(:base, "User with uid '#{record.uid}' and provider '#{record.provider}' already exists.")
  end
end
