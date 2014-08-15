class User < ActiveRecord::Base

	has_many :statuses, :as => :statusable

  require 'net/ldap'
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'json'
  require 'yaml'
  require 'rest_client'
  APP_REPLICON = YAML.load_file(Rails.root.to_s + '/config/replicon.yml')
  APP_AD = YAML.load_file(Rails.root.to_s + "/config/ad.yml")

  #fills the user table with users from active directory and 
  #gets the replicon uri ID for each user 
  #then deletes users without a replicon uri
	def self.import_all
		ldap = Net::LDAP.new(:host => "192.168.8.101", :port => 389, :base => "DC=sbstone, DC=com",  :auth => {:method => :simple, :username => "sbstone\\ldaptest", :password => "Level77#"})
    if ldap.bind
      puts "Connection successful!  Code:  #{ldap.get_operation_result.code}, message: #{ldap.get_operation_result.message}"
    else
      puts "Connection failed!  Code:  #{ldap.get_operation_result.code}, message: #{ldap.get_operation_result.message}"
    end
		begin
			filter = Net::LDAP::Filter.eq("sAMAccountName", "*")
      filter2 = Net::LDAP::Filter.eq("objectCategory", "organizationalPerson")
      joined_filter = Net::LDAP::Filter.join(filter, filter2)
			attrs = ["givenName", "sn", "sAMAccountName"]
			records = new_records = 0
			ldap.search(:attributes => attrs, :filter => joined_filter, :return_result => false) do |entry|
        if entry.respond_to?('givenName') && entry.respond_to?('sn')
          name =  entry.sn.to_s.gsub(/[^0-9A-Za-z]/, '') + ", " + entry.givenName.to_s.gsub(/[^0-9A-Za-z]/, '')
          username = entry.sAMAccountName.to_s.strip.gsub(/[^0-9A-Za-z]/, '')
          email = entry.sAMAccountName.to_s.strip.gsub(/[^0-9A-Za-z]/, '') + "@lvlsvn.com"
          if !User.exists?(:name => name) && !User.exists?(:user_name => username) && !User.exists?(:email => email)
            user = User.create(:name => name, :user_name => username, :email => email)
            if user.new_record?
              user.save
              new_records = new_records + 1
            else
              user.touch
            end
            records = records + 1
          end
        end
      end
      p ldap.get_operation_result
      logger.info("LDAP Import Complete: " + Time.now.to_s)
      logger.info("Total Records Processed: " + records.to_s)
      logger.info("New Records: " + new_records.to_s)
      self.all_users
      self.all.each do |user|
        if user.replicon_uri == nil || !interactive_marketing?(user.replicon_uri)
          user.destroy
        end
      end
    end
    return nil
  end

  # Change these parameters to point at any Web TimeSheet instance
  # http://$host:$port/$path
  $loginname = APP_REPLICON['name']
  $password = APP_REPLICON['password']
  $port = 80
  $path = ''
  $host = 'https://na2.replicon.com'

  # Query to return all users
  def self.all_rep_users
    resource = RestClient::Resource.new($host, "levelseven\\#{$loginname}", $password)
    $path = '/levelseven/services/UserService1.svc/GetEnabledUsers'
    response = resource[$path].post '{
    }'
    rep_users = response.body.gsub("{\"d\":[", "").gsub("]}", "").gsub(",{", "").gsub("{", "").split("}")
    
    rep_users.each do |uri|
      if self.find_by_name(uri.partition(",\"loginName").first.partition(":").last.gsub("\"", ""))
        user = self.find_by_name(uri.partition(",\"loginName").first.partition(":").last.gsub("\"", ""))
        user.user_name = uri.partition(",\"loginName\":\"").last.partition(",\"slug\"").first.gsub("\"", "")
        user.replicon_uri = uri.partition(",\"uri\":").last.gsub("\"", "")
        user.save
      end        
    end
    return nil
  end

  #See if anyone is out for vacation today
  def self.all_users_time_off
    resource = RestClient::Resource.new($host, "levelseven\\#{$loginname}", $password)
    $path = '/levelseven/services/TimeOffService1.svc/GetTimeOffDetailsForUserAndDateRange'
    self.all.each do |replicon_user|
      time_off = resource[$path].post "{
        \"userUri\": \"#{replicon_user.replicon_uri}\",
        \"dateRange\": {
          \"startDate\": {
           \"year\": #{DateTime.now.year},
            \"month\": #{DateTime.now.month},
            \"day\": #{DateTime.now.day}
          },
          \"endDate\": {
            \"year\": #{(DateTime.now + 1).year},
            \"month\": #{(DateTime.now + 1).month},
            \"day\": #{(DateTime.now + 1).day}
          },
          \"relativeDateRangeUri\": null,
          \"relativeDateRangeAsOfDate\": null
        }
      }", :content_type => :json
      if time_off == "{\"d\":[]}"
        puts "#{replicon_user.name} is not on vacation."
      else
        puts "#{replicon_user.name} is out of here!"
        status = Status.new
        status.body = "Vacation"
        status.expiration = DateTime.now + 1
        status.statusable_id = replicon_user.id
        status.save
      end      
    end
    return nil
  end

  #Checks if the user is past of Interactive Marketing department
  def self.interactive_marketing? (userUri)
    resource = RestClient::Resource.new($host, "levelseven\\#{$loginname}", $password)
    $path = '/levelseven/services/DepartmentService1.svc/GetDepartmentForUser'
    department = resource[$path].post "{
      \"userUri\": \"#{userUri}\"
    }", :content_type => :json
    if department.split(",\"uri\":\"").last.gsub("\"}}", "") == "urn:replicon-tenant:lsgen3:department:10"
      return true
    else
      return false
    end
  end

  def self.to_csv
    if Status.all.empty?
      ary = Array.new(2)
      ary[0] = "Everybody"
      ary[1] = "is in"
      CSV.generate do |csv|
        csv << ary.slice(0,1)
        csv << ary.slice(1,1)
      end
    else
      ary = Array.new(1)
      ary[0] = "Status"
      CSV.generate do |csv|
        csv << column_names.slice(3,1) + ary
        i = 0
        all.each do |user|
          if out_users = self.users_in?(user.attributes.values_at(*column_names[3])).slice(i, 1)
            csv << out_users + self.current_status_all_users(user.attributes.values_at(*column_names[3])).slice(i, 1)
          end
          i += 1
        end
      end
    end
  end

  private 
  def self.current_status_all_users(name)
    ary = Array.new(User.count)
    i = 0
    User.all.each do |user|
      if @status = Status.find_by_statusable_id(user.id)
        ary[i] = @status.body
        if ary[i]== "Out of Office"
          ary[i] = "OoO"
        elsif ary[i] == "Working From Home"
          ary[i] = "WFH"
        elsif ary[i] == "Vacation"
          ary[i] = "Vac"
        end
        i += 1
      end
    end
    ary.compact!
    return ary
  end

  private
  def self.users_in?(name)
    ary = Array.new(User.count)
    i = 0
    User.all.each do |user|
      if Status.find_by_statusable_id(user.id)
        ary[i] = user.user_name
        i += 1
      end
    end
    ary.compact!
    return ary
  end

end