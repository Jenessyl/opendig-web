class User < ApplicationRecord
  enum access_level: { viewer: 0, editor: 1, admin: 2 }

  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :provider, presence: true
  validates :email, presence: true

  def role_at_least?(role)
    access_level_before_type_cast >= User.access_levels[role]
  end
end
