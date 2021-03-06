class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  has_many :likes, :as => :likeable
  has_many :replies, dependent: :destroy

  after_create :send_comment_notification

  default_scope { order('created_at DESC') }

  validates :body, presence: true

  def send_comment_notification
    post = self.post
    comment = self
    if Rails.env.production?
      recipients = User.where(role: "admin").pluck(:email)
      recipients.each do |recipient|
        UserMailer.comment_notification(post, comment, recipient).deliver_later
      end
    else
      UserMailer.comment_notification(post, comment, "isorme1@gmail.com").deliver_later
    end
  end

end
