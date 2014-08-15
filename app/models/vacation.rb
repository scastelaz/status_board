class Vacation < ActiveRecord::Base

	require 'net/ldap'
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'json'
  require 'yaml'
  require 'rest_client'
  require 'base64'
  require 'icalendar'
  require 'icalendar'
  APP_REPLICON = YAML.load_file(Rails.root.to_s + '/config/replicon.yml')

  #See if anyone is out for vacation this month
  def self.get_vacation_for_month
  	loginname = APP_REPLICON['name']
  	password = APP_REPLICON['password']
  	port = 80
  	host = 'https://na2.replicon.com'
    resource = RestClient::Resource.new(host, "levelseven\\#{loginname}", password)
    path = '/levelseven/services/TimeOffService1.svc/GetTimeOffDetailsForUserAndDateRange'
    User.all.each do |replicon_user|
      time_off = resource[path].post "{
        \"userUri\": \"#{replicon_user.replicon_uri}\",
        \"dateRange\": {
          \"startDate\": {
           \"year\": #{DateTime.now.year},
            \"month\": #{DateTime.now.month},
            \"day\": #{DateTime.now.day}
          },
          \"endDate\": {
            \"year\": #{(DateTime.now + 30).year},
            \"month\": #{(DateTime.now + 30).month},
            \"day\": #{(DateTime.now + 30).day}
          },
          \"relativeDateRangeUri\": null,
          \"relativeDateRangeAsOfDate\": null
        }
      }", :content_type => :json
      if time_off == "{\"d\":[]}"
        puts "#{replicon_user.name} has no vacation this month."
      else
        puts "#{replicon_user.name} has vacation this month."
        while time_off.include?("approvalStatus")
   				if time_off.partition("displayText\":\"").last.partition("\",\"").first == "Approved"
   				  temp = time_off.partition("displayText\":\"").last.partition("\",\"").last
   					endTime = temp.partition("date").last.partition("relative").first
   					startTime = temp.partition("date").last.partition("date").last.partition("relative").first
   					endTime = Date.new(endTime.partition("year\":").last.partition("}").first.to_i, endTime.partition("month\":").last.partition(",\"year").first.to_i, endTime.partition("day\":").last.partition("\"month").first.to_i)
   					startTime = Date.new(startTime.partition("year\":").last.partition("}").first.to_i, startTime.partition("month\":").last.partition(",\"year").first.to_i, startTime.partition("day\":").last.partition("\"month").first.to_i)
   				  vac = Vacation.find_by_startDate(startTime)
            if vac != nil 
              if vac.user_id == replicon_user.id
                
              else
                vacation = Vacation.create(:startDate => startTime, :endDate => endTime, :user_id => replicon_user.id)
              end
            else
              vacation = Vacation.create(:startDate => startTime, :endDate => endTime, :user_id => replicon_user.id)
            end
          end
   				time_off = time_off.partition("approvalStatus").last
        end
      end      
    end
    return nil
  end

  def self.to_csv
  	ary = Array.new(1)
  	ary[0] = 'Name'
    CSV.generate do |csv|
      csv << ary + column_names.slice(1,2)
      all.order('startDate').each do |user|
        csv <<  self.find_users(user.attributes.values_at(*column_names.slice(3,1))) + user.attributes.values_at(*column_names.slice(1,2))
      end
    end
  end

  def self.to_ics
    cal = Icalendar::Calendar.new
    Vacation.all.each do |vac|
      event = Icalendar::Event.new
      event.dtstart = vac.startDate.strftime("%Y%m%dT%H%M%S")
      event.dtend = vac.endDate.strftime("%Y%m%dT%H%M%S")
      event.summary = User.find(vac.user_id).name
      cal.add_event(event)
    end
    cal.publish
    cal.to_ical
  end

  def self.find_users(ids)
  	ary = Array.new(ids.length)
  	i = 0
  	ids.each do |id|
  		user = User.find(id)
  		ary [i] = user.user_name
  	end
  	return ary
  end

  def self.delete_expired!
		self.all.each do |vacation|
			if vacation.endDate == nil
				vacation.destroy
			elsif vacation.endDate < DateTime.now
				vacation.destroy
			end
		end
	end

end