class Mesh < ActiveRecord::Base
  has_many :sessions, dependent: :destroy
  has_attached_file :upload

  store :data, accessors: [ :name ], coder: JSON

  # Validations
  do_not_validate_attachment_file_type :upload
  validates :upload, attachment_presence: true
  validates :upload_file_name, uniqueness: true
end
