# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_cruisecontrol.rb_session',
  :secret      => 'bbea68db1dca5217885b02cfaa80b7d86df9898871e15ccbefc2c26c8c48990007dda2598376b73eac37dd9b8190b550d2a1c62479cbae7483f19b4ffdb3f584'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
