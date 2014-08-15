class Status < ActiveRecord::Base

	belongs_to :user

	def self.delete_expired!
		self.all.each do |status|
			if status.expiration == nil
				status.destroy
			elsif status.expiration < DateTime.now
				status.destroy
			end
		end
	end

	def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.each do |user|
        csv << user.attributes.values_at(*column_names)
      end
    end
  end

end