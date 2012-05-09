# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
config.action_mailer.raise_delivery_errors = false

ActiveSupport::XmlMini.backend = 'LibXML'

# set constants containing sensitive information
# # such as passwords for sendgrid, etc.
extra_conf = "/data/extra-conf/environment-variables.rb"
if File.exists?(extra_conf)
  require extra_conf
end

# allourideas app
HOST                = 'localhost:3001'

# pairwise api
API_HOST            = 'http://localhost:3000'
PAIRWISE_USERNAME   = 'SET_HERE_PAIRWISE_API_USERNAME'
PAIRWISE_PASSWORD   = 'PAIRWISE_API_PASSWORD'

# photocracy api
PHOTOCRACY_HOST     = 'photocracy.org'
PHOTOCRACY_USERNAME = 'PHOTOCRACY_API_USERNAME'
PHOTOCRACY_PASSWORD = 'PHOTOCRACY_API_PASSWORD'

# prevent dictionary attacks on stored ip address hashes
IP_ADDR_HASH_SALT   = '2039d9ds9ufsdioh2394230'
