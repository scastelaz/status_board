class VacMailer < ActionMailer::Base
  require 'icalendar'
	def ical_test
		mail(:to => "dashboard@lvlsvn.com", :subject => "iCalendar",
                  :from => "scheduler@lvlsvn.com") do |format|
	       format.ics {
	       ical = Icalendar::Calendar.new
	       e = Icalendar::Event.new
	       e.dtstart = DateTime.now
	       e.dtend = (DateTime.now + 1.day)
	       e.organizer = "any_email@example.com"
	       e.uid = "MeetingRequest"
	       e.summary = "Scrum Meeting"
	       e.description = <<-EOF
	         Venue: Office
	         Date: 16 August 2011
	         Time: 10 am
	       EOF
	       ical.add_event(e)
	       ical.publish
	       ical.to_ical
	       render :text => ical, :layout => false
	      }
	    end
	    mail.deliver
	end

end
