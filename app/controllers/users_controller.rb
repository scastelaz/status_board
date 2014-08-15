class UsersController < ApplicationController

  skip_before_filter :verify_authenticity_token

  require 'yaml'
  APP_AD = YAML.load_file(Rails.root.to_s + "/config/ad.yml")

	def index
    @users = User.all
    respond_to do |format|
      format.html
      format.json {render json: @users}
      format.csv {render text: @users.to_csv}
    end
  end

	def show
    @user = nil
    if is_number? (params[:id])
      @user = User.find(params[:id])
    else
      @user = User.find_by_user_name("#{(params[:id])}")
    end
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
      format.csv {render text: @user.to_cvs}
    end
  end

  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
      format.csv {render text: @user.to_cvs}
    end
  end

  def edit
  	@user = User.find(params[:id])
  end

  def create
  	@user = User.new(user_params)
  	respond_to do |format|
  		if @user.save
  			format.html {redirect_to @user, notice: 'User was successfully created'}
  			format.json {render json: @user, status: :created}
        format.csv {render text: @user.to_cvs}
  		else
  			format.html {render action: "new"}
  			format.json {render json: @user.errors, status: :unprocessable_entry}
  		end
  	end
  end

  def update
  	@user = User.find(params[:id])

  	respond_to do |format|
  		if @user.update_attributes(params[:user])
  			format.html {redirect_to @user, notice: 'User successfully updated.'}
  			format.json {head :no_content}
        format.csv {render text: @user.to_cvs}
  		else
  			format.html {render action: "edit"}
  			format.json { render json: @user.errors, status: :unprocessable_entry}
  		end
  	end
  end

  def destroy
   @user = User.find(params[:id])
   @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
      format.csv {render text: @user.to_cvs}
    end
  end

  private
  def user_params
    params.require(:user).permit(:email, :user_name, :id, :replicon_uri)
  end

  
end