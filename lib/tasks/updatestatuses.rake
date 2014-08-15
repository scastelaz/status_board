namespace :scripts do 

	desc "Updates the statuses of all users"
	task :update_status do 
		Vacation.get_vaction_time
		Status.clear_expired_statuses
	end
	
end