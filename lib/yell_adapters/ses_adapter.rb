require 'yell'
require 'aws-sdk'

class SesAdapter < Yell::Adapters::Base
  include Yell::Helpers::Base
  include Yell::Helpers::Formatter

  attr_accessor :ses, :body_text, :email_config, :errors

  setup do |options|
    self.formatter = options[:format]
    self.ses = AWS::SimpleEmailService.new(
      access_key_id: options[:aws_access_key_id],
      secret_access_key: options[:aws_secret_access_key]
    )
    self.email_config = options[:email_config]
    self.body_text = ''
    self.errors = false
  end

  write do |event|
    self.body_text += formatter.call(event)
    self.errors = true if event.level >= 3
  end

  close do
    base_subject = email_config['subject'] + Time.now.utc.strftime(' %Y/%m/%d')
    subject = format_subject(base_subject)
    ses.send_email(
      subject: subject,
      from: email_config['from_address'],
      to: email_config['to_addresses'],
      body_text: body_text
    )
  end

  private

  def errors?
    errors
  end

  def format_subject(base_subject)
    errors? ? "Error: #{base_subject}" : "Sucess: #{base_subject}"
  end
end

Yell::Adapters.register :ses_adapter, SesAdapter
