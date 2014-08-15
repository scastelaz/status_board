class StatusesController < ApplicationController

  skip_before_filter :verify_authenticity_token

  require 'yaml'
  APP_AD = YAML.load_file(Rails.root.to_s + "/config/ad.yml")
  APP_HIPCHAT =YAML.load_file(Rails.root.to_s + "/config/hipchat.yml")

	def index
    @user = nil
    if is_number? (params[:user_id])
      @user = User.find(params[:user_id])
    else
      @user = User.find_by_user_name("#{(params[:user_id])}")
    end
    puts @user.id
    @statuses = Status.where(:statusable_id => @user.id)
    puts @statuses
    respond_to do |format|
      format.html
      format.json {render json: @statuses}
      format.csv {render text: @statuses.to_csv}
    end
  end

	def show
    @user = nil
    if is_number? (params[:user_name])
      @user = User.find(params[:user_name])
    else
      @user = User.find_by_user_name("#{(params[:user_name])}")
    end
    @statuses = User.find_by_statusable_id(@user.id)
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @status }
      format.csv {render text: @status.to_cvs}
    end
  end

  def new
    @status = Status.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @status }
      format.csv {render text: @status.to_cvs}
    end
  end

  def edit
  	@status = Status.find(params[:id])
  end

  def create
    @user = nil
    puts (params[:user_name])
    if is_number? (params[:user_name])
      @user = User.find(params[:user_name])
    else
      @user = User.find_by_user_name("#{(params[:user_name])}")
    end
    @status = Status.new(status_params)
    @status.statusable_id = @user.id
    @status.expiration = (DateTime.now + 1)
    api_token = APP_HIPCHAT['token']
    api_version = APP_HIPCHAT['api_version']
    room = APP_HIPCHAT['room']
    user = APP_HIPCHAT['user']
    client = HipChat::Client.new(api_token, :api_version => api_version)
  	respond_to do |format|
  		if @status.save
  			format.html {redirect_to @status, notice: 'status was successfully created'}
  			format.json {render json: @status, status: :created}
        format.csv {render text: @status.to_cvs}
        #client[room].send('scastelaz', "@here #{User.find(@status.statusable_id} is #{@status.body}", :color => 'green')
  		else
  			format.html {render action: "new"}
  			format.json {render json: @status.errors, status: :unprocessable_entry}
  		end
  	end
  end

  def update
  	@status = Status.find(params[:id])
  	respond_to do |format|
  		if @status.update_attributes(params[:status])
  			format.html {redirect_to @status, notice: 'status successfully updated.'}
  			format.json {head :no_content}
        format.csv {render text: @status.to_cvs}
  		else
  			format.html {render action: "edit"}
  			format.json { render json: @status.errors, status: :unprocessable_entry}
  		end
  	end
  end

  def destroy
    @status = Status.find(params[:id])
    @status.destroy
    respond_to do |format|
      format.html { redirect_to statuss_url }
      format.json { head :no_content }
      format.csv {render text: @status.to_cvs}
    end
  end

  private
  def status_params
    params.require(:status).permit(:body, :expiration, :id, :statusable_id, :statusable_type)
  end
end