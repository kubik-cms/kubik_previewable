class NewsArticle < ApplicationRecord
  include Kubik::Previewable
  kubik_previewable
end
