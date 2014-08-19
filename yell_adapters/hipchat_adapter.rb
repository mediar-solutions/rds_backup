require 'yell'
require 'hipchat'

class HipchatAdapter < Yell::Adapters::Base
  include Yell::Helpers::Base
  include Yell::Helpers::Formatter

  attr_accessor :hipchat, :body_text, :hipchat_rooms, :errors

  setup do |options|
    self.formatter = options[:format]
    self.hipchat = HipChat::Client.new(
      options[:hipchat_token], api_version: 'v2'
    )
    self.hipchat_rooms = options[:hipchat_rooms]
    self.body_text = ''
    self.errors = false
  end

  write do |event|
    self.body_text += formatter.call(event)
    self.errors = true if event.level >= 3
  end

  close do
    format_body_text_to_html
    color = errors? ? 'red' : 'green'
    hipchat_rooms.each do |room|
      hipchat[room].send('RDS Backup', body_text, message_format: 'html',
                                                  color: color)
    end
  end

  private

  def errors?
    errors
  end

  def format_body_text_to_html
    body_text.gsub!("\n", '<br>')
    prepend = errors? ? '<strong>Error!</strong>' : '<strong>Success!</strong>'
    self.body_text = [prepend, body_text].join '<br>'
  end
end

Yell::Adapters.register :hipchat_adapter, HipchatAdapter
