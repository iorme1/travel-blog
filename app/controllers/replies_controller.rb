class RepliesController < ApplicationController
  invisible_captcha only: [:create, :update], honeypot: :subtitle, on_spam: :spam_detected
  before_action :authorize_user
  before_action :set_post, only: [:new, :create, :destroy, :like, :edit, :update, :like]
  before_action :set_comment, only: [:new, :show, :create, :edit, :update]
  before_action :set_reply, only: [:destroy, :edit, :update, :like]

  def show
  end

  def new
    @reply = @comment.replies.new
  end

  def create
    @reply = @comment.replies.new(reply_params)
    @reply.user = current_user

    if @reply.save
      if @comment.user.subscription?
        @recipient = @comment.user.email
        UserMailer.reply_notification(@recipient, current_user.email, @reply, @post).deliver_later
      end
      flash[:notice] = "Reply saved successfully."
      redirect_to @post
    else
      flash[:alert] = "Reply failed to save. Please try again."
      redirect_to @post
    end
  end

  def edit
  end

  def update
    @reply.assign_attributes(reply_params)

    if @reply.save
      flash[:notice] = "Comment has been updated."
      redirect_to @post
    else
      flash.now[:alert] = "There was an error updating that comment. Please try again."
      render :edit
    end
  end

  def destroy
    if @reply.destroy
      flash[:notice] = "Your reply was deleted."
    else
      flash[:alert] = "Replay was not deleted. Please try again."
    end
    redirect_to @post
  end

  def like
    @like = Like.where(likeable: @reply, user_id: current_user)

    unless @like.size >= 1
      @recipient = User.where(subscription: true).where(id: @reply.user_id).pluck(:email)
      Like.create(likeable: @reply,  user: current_user, like: params[:like])
      if @recipient
        UserMailer.reply_like_notification(@recipient, current_user.email.split('@')[0], @reply, @post).deliver_later
      end
    end
  end

  private

  def reply_params
    params.require(:reply).permit(:body)
  end

  def set_reply
    @reply = Reply.find(params[:id])
  end

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_comment
    @comment = Comment.find(params[:comment_id])
  end

  def spam_detected
    redirect_to root_path
  end

  def authorize_user
    unless current_user && (current_user.member? || current_user.admin?)
      flash[:alert] = "You must be member to reply. Sign up for free now!"
      redirect_to root_path
    end
  end

end