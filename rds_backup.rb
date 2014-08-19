require 'fog'
require 'open3'
require_relative 'yell_adapters/ses_adapter'
require_relative 'yell_adapters/hipchat_adapter'

class RdsBackup
  def initialize
    config = YAML.load(File.open('config.yml'))
    config_google(config)
    config_mysql(config)
    config_logger(config)

    @backups_to_keep = config['backups_to_keep'] || 3
    current_utc_time = Time.now.getutc.strftime('%Y%m%d%H%M%S')
    @file_name = "#{mysql_database}-#{current_utc_time}.sql.bz2"
  end

  def backup
    begin
      dump_database
      upload_backup
      prune_old_backups
    rescue
    ensure
      logger.close
    end
  end

  private

  attr_accessor :mysql_database, :mysql_host, :mysql_user, :mysql_password,
                :fog_directory, :file_name, :backups_to_keep, :logger

  def config_mysql(config)
    @mysql_database = config['mysql']['database']
    @mysql_host = config['mysql']['host']
    @mysql_user = config['mysql']['user']
    @mysql_password = config['mysql']['password']
  end

  def config_google(config)
    google_access = config['cloud_storage']['access_key_id']
    google_secret = config['cloud_storage']['secret_access_key']
    connection = Fog::Storage.new(
      provider: 'Google',
      google_storage_access_key_id: google_access,
      google_storage_secret_access_key: google_secret
    )
    @fog_directory = connection.directories.get('idxp-rds-backup')
  end

  def config_logger(config)
    @logger = Yell.new do |l|
      l.adapter :ses_adapter, {
        format: Yell::BasicFormat,
        aws_access_key_id: config['aws']['access_key_id'],
        aws_secret_access_key: config['aws']['secret_access_key'],
        email_config: config['email']
      }
      l.adapter :hipchat_adapter, {
        format: Yell::BasicFormat,
        hipchat_token: config['hipchat']['token'],
        hipchat_rooms: config['hipchat']['rooms']
      }
    end
  end

  def dump_database
    cmd = "mysqldump -u#{mysql_user} "
    cmd += "-p#{mysql_password} " if mysql_password
    cmd += "--single-transaction --routines --triggers "\
           "-h #{mysql_host} #{mysql_database} "\
           "| bzip2 -c > #{file_name}"
    out, err, _status = Open3.capture3 cmd

    if err.empty?
      logger.info 'Database dump successfully created'
    else
      logger.error "Error when dumping the database: #{err.strip}"
      Open3.capture3 "rm -rf #{file_name}"
      fail RuntimeError
    end
  end

  def upload_backup
    begin
      fog_directory.files.create(
        key: file_name,
        body: File.open(file_name)
      )
      logger.info 'Backup uploaded to Google'
    rescue
      logger.error 'Error while uploading dump to Google'
    end
  end

  def prune_old_backups
    begin
      sorted_files = fog_directory.files.reload.sort do |x, y|
        x.last_modified <=> y.last_modified
      end
      sorted_files[0 .. -backups_to_keep - 1].each { |f| f.destroy }
      logger.info 'Old backups pruned'
    rescue
      logger.error 'Error while pruning old backups'
    end
  end
end
