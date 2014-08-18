require 'fog'
require 'open3'

class RdsBackup

  def initialize
    config = YAML.load(File.open('config.yml'))

    @google_access = config['cloud_storage']['access_key_id']
    @google_secret = config['cloud_storage']['secret_access_key']
    @mysql_database = config['mysql']['database']
    @mysql_host = config['mysql']['host']
    @mysql_user = config['mysql']['user']
    @mysql_password = config['mysql']['password']
    @backups_to_keep = config['backups_to_keep'] || 3

    current_utc_time = Time.now.getutc.strftime("%Y%m%d%H%M%S")
    @file_name = "#{mysql_database}-#{current_utc_time}.sql.bz2"

    connection = Fog::Storage.new(
      provider: 'Google',
      google_storage_access_key_id: google_access,
      google_storage_secret_access_key: google_secret
    )
    @fog_directory = connection.directories.get('idxp-rds-backup')
  end

  def backup
    dump_database
    upload_backup
    prune_old_backups
  end

  private

  attr_accessor :google_access, :google_secret, :mysql_database, :mysql_host,
                :mysql_user, :mysql_password, :fog_directory, :file_name

  def dump_database
    cmd = "mysqldump -u#{mysql_user} "
    cmd += "-p#{mysql_password} " if mysql_password
    cmd += "-h #{mysql_host} #{mysql_database} | bzip2 -c > #{file_name}"
    out, err, status = Open3.capture3 cmd
  end

  def upload_backup
    file = fog_directory.files.create(
      key: file_name,
      body: File.open(file_name),
    )
  end

  def prune_old_backups
    sorted_files = fog_directory.files.reload.sort do |x, y|
      x.last_modified <=> y.last_modified
    end
    sorted_files[0 .. -backups_to_keep - 1].each { |f| f.destroy }
  end
end
