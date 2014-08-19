# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rds_backup/version'

Gem::Specification.new do |spec|
  spec.name          = 'rds_backup'
  spec.version       = RdsBackup::VERSION
  spec.authors       = ['Artur Rodrigues']
  spec.email         = ['arturhoo@gmail.com']
  spec.description   = %q{Backup RDS Databases and sync them to multiple cloud providers}
  spec.summary       = %q{Backup RDS Databases}
  spec.homepage      = 'https://github.com/idxp/rds_backup'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry_byebug'

  spec.add_dependency 'aws-sdk'
  spec.add_dependency 'fog'
  spec.add_dependency 'yell'
  spec.add_dependency 'hipchat'
end
