# require your app file first
require './app'
require 'sinatra/activerecord/rake'


desc "This task is called by the Heroku scheduler add-on"

task :send_daily_bother do

  ActiveRecord::Base.connection
  client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]

  User.all.each do |u|
    
    message = "Daily update: \n"
    u.tracks.each do |t|
      message += "We miss you! Text +1(646)-217-4207 to start the translation service:)"
    end
    
    client.account.messages.create(
      :from => ENV["TWILIO_FROM"],
      :to => u.phone_number,
      :body => message
    )
    
  end

end
