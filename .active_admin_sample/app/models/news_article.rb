class NewsArticle < ApplicationRecord
  include Kubik::KubikPreviewable
  kubik_previewable
end
