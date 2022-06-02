class Book < ApplicationRecord
  include Kubik::Uploadable

  GENRES = %i[thriller crime horror fantasy]

  has_one_kubik_upload(:book_cover, :cover)
  has_many_kubik_uploads(:book_gallery, :gallery)

  belongs_to :book_author
  has_many :book_editions
  accepts_nested_attributes_for :book_editions, allow_destroy: true

  validates_presence_of :title
  delegate :name, to: :book_author, prefix: true
end
