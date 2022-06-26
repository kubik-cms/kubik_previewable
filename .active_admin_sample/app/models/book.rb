class Book < ApplicationRecord

  GENRES = %i[thriller crime horror fantasy]

  belongs_to :book_author
  has_many :book_editions
  accepts_nested_attributes_for :book_editions, allow_destroy: true

  validates_presence_of :title
  delegate :name, to: :book_author, prefix: true
end
