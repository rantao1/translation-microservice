require 'json'
require "sinatra"
require 'active_support/all'
require "active_support/core_ext"
require 'sinatra/activerecord'
require 'rake'

require 'twilio-ruby'
require 'easy_translate'

require_relative './models/user'
require_relative './models/log'
require_relative './models/track'

configure :development do
  require 'dotenv'
  Dotenv.load
end
 
enable :sessions

client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
EasyTranslate.api_key = ENV['GOOGLE_API_KEY']


get '/' do

  "please text +1(646)-217-4207 to start the translation service!".to_s

end



get '/translate' do

	session["last_stage"] ||= nil
  sender = params[:From] || ""
  body = params[:Body] || ""
  body = body.strip
  supported_language = EasyTranslate::LANGUAGES
  session["language_translation"] ||= nil

  if check_user_exists ( sender )

    user = get_user sender

    if session["last_stage"] == "begin_registration"
      user.name = body 
      user.save!
      session["last_stage"] = "confirm_tandc"
      
      twiml = Twilio::TwiML::Response.new do |r|
        r.Message "Thanks #{user.first_name}. Just to check, you agree to the terms and conditions and will be ok to get one SMS notification daily?"
      end
      twiml.text

    elsif session["last_stage"] == "confirm_tandc" and  body.include? "yes"
      user.agreed_to_terms = true 
      user.save!
      session["last_stage"] = "choose_language"
      session["language_translation"] = nil
      twiml = Twilio::TwiML::Response.new do |r|
        r.Message "Great #{user.first_name}. Thank you for choosing this translation service. Now, Input the language abbreviation you want to translate to.
                We support the following languages:
                #{supported_language}"
      end
      twiml.text

    elsif session["last_stage"] == "confirm_tandc" and body.include? "no"
      user.agreed_to_terms = false 
      user.save!
      session["last_stage"] = "confirm_tandc"
      
      twiml = Twilio::TwiML::Response.new do |r|
        r.Message "We're at an impass. I need you to confirm that if you want to use this translation service"
      end
      twiml.text

  	elsif user.agreed_to_terms and session["last_stage"] == "start_service" or body == "reset"
      session["language_translation"] = nil
    	twiml = Twilio::TwiML::Response.new do |r|
      r.Message "Input the language abbreviation you want to translate to.
                We support the following languages:
                #{supported_language}"
      session["last_stage"] == "choose_language"
    	end
      twiml.text
    
    elsif user.agreed_to_terms and session["last_stage"] == "choose_language"
        #if the body matches the database, proceed, otherwise, reinput
          session["language_translation"] = "#{body}"
    		  twiml = Twilio::TwiML::Response.new do |r|
          r.Message "Input the text you want to translate(we can automatically detect what language you input)"
          session["last_stage"] == "translate_input"
          end
          twiml.text


    elsif user.agreed_to_terms and session["last_stage"] == "translate_input" and body != "reset"
        translation_message = EasyTranslate.translate(body, :to => "#{session["language_translation"]}")
        twiml = Twilio::TwiML::Response.new do |r|
          r.Message "#{body}<br>means<br>#{translation_message}<br>in<br>#{session["language_translation"]}<br>tip: input another text to keep translating or input 'reset' to reset the language you want to translate to"
        end
        twiml.text

    else
        language_translation = ""
        twiml = Twilio::TwiML::Response.new do |r|
        r.Message "Input the language abbreviation you want to translate to. 
                  We support the following languages: 
                  #{supported_language}"
        session["last_stage"] == "choose_language"
        end
        twiml.text

      end
   
    else
      if session["last_stage"] == "ask_for_registration" and body.include? "yes"
      begin_registration sender 
    elsif session["last_stage"] == "ask_for_registration" and body.include? "no"
      error_out
    else 
      ask_for_registration
    end
  end
    
end

private 

  def check_user_exists from_number
    User.where( phone_number: from_number ).count > 0
  end

  def get_user from_number
    User.where( phone_number: from_number ).first
  end

  def ask_for_registration
  
    session["last_stage"] = "ask_for_registration"
  
    twiml = Twilio::TwiML::Response.new do |r|
      r.Message "It doesn't look like you're registered. Would you like to get set up now?"
    end
    twiml.text
  
  end

  def begin_registration sender
  
    session["last_stage"] = "begin_registration"
  
    user = User.create( phone_number: sender )
  
    twiml = Twilio::TwiML::Response.new do |r|
      r.Message "Great. I'll get you set up. First, what's your name?"
    end
    twiml.text
  
  end 

  def error_out 
  
    session["last_stage"] = "no registration"
    twiml = Twilio::TwiML::Response.new do |r|
      r.Message "We're at an impass. I need you to register if you want to use the translation service"
    end
    twiml.text 
  
  end 

















