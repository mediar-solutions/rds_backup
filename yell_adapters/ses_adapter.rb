require 'yell'
require 'aws-sdk'
require 'pry-byebug'

class SesAdapter < Yell::Adapters::Base
  include Yell::Helpers::Base
  include Yell::Helpers::Formatter

  attr_accessor :ses, :body_text, :email_config

  setup do |options|
    self.formatter = options[:format]
    self.ses = AWS::SimpleEmailService.new(
      access_key_id: options[:aws_access_key_id],
      secret_access_key: options[:aws_secret_access_key]
    )
    self.email_config = options[:email_config]
    self.body_text = ''
  end

  write do |event|
    self.body_text += formatter.call(event)
  end

  close do
    ses.send_email(
      subject: 'Test email',
      from: email_config['from_address'],
      to: email_config['to_addresses'],
      body_text: body_text
    )
  end
end

Yell::Adapters.register :ses_adapter, SesAdapter
