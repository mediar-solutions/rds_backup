require 'fog'
require 'open3'

config = YAML.load(File.open('config.yml'))

google_config = config['cloud_storage']
connection = Fog::Storage.new({
  provider: 'Google',
  google_storage_access_key_id: google_config['access_key_id'],
  google_storage_secret_access_key: google_config['secret_access_key']
})

mysql_config = config['mysql']
file_name = "#{mysql_config['database']}"\
            "#{Time.now.getutc.strftime("%Y%m%d%H%M")}.sql.bz2"

cmd = "mysqldump -u#{mysql_config['user']} "
cmd += "-p#{mysql_config['password']} " if mysql_config['password']
cmd += "-h #{mysql_config['host']} #{mysql_config['database']} | "\
       "bzip2 -c > #{file_name}"

out, err, status = Open3.capture3 cmd

dir = connection.directories.get('idxp-rds-backup')
file = dir.files.create(
  key: file_name,
  body: File.open(file_name),
)

sorted_files = dir.files.reload.sort do |x, y|
  x.last_modified <=> y.last_modified
end
sorted_files[0..-3].each { |f| f.destroy }
