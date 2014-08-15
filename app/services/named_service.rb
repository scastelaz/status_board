class UpdateStatus

	def get_vaction_today
		User.all_users.time_off
	end

	def clear_expired_statuses
		Status.delete_expired!
	end
end