require 'aws-sdk'

class CustomLogger
  def initialize
    config = YAML.load(File.open('config.yml'))
    configure_std
    configure_aws(config)
    # configure_hipchat(config)

    @email_from = config['email']['from_address']
    @email_to = config['email']['to_addresses']
  end

  def log(status, message)
    log_to_std(status, message)
    log_to_email(status, message)
    # log_to_hipchat(status, message)
  end

  private

  attr_accessor :std_logger, :ses, :email_from, :email_to

  def configure_std
    @std_logger = Logger.new(STDOUT)
    @std_logger.level = Logger::INFO
    @std_logger.datetime_format = '%Y-%m-%d %H:%M:%S '
  end

  def configure_aws(config)
    @ses = AWS::SimpleEmailService.new(
      access_key_id: config['aws']['access_key_id'],
      secret_access_key: config['aws']['secret_access_key']
    )
  end

  def configure_hipchat
  end

  def log_to_std(status, message)
    if status == 0
      std_logger.debug message
    else
      std_logger.error message
    end
  end

  def log_to_email(status, message)
    email = { from: email_from, to: email_to }
    if status == 0
      email[:subject] = 'RDS Backup Done'
      email[:body_text] = message
    else
      email[:subject] = 'RDS Backup went wrong'
      email[:body_text] = message
    end
    ses.send_email email
  end

  def log_to_hipchat
  end
end
