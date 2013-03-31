# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# guest users are default users who have limited api access.
# no users can signup as 'guest', but can signin as guest, if they hack the pass.
# create them as 'admin' so that they don't show up in the app.
User.create!(:username => 'guest', :password => SECURE_TREE['default_pass'], :email => 'guest@fontli.com', :admin => true)
User.create!(:username => 'fontli', :full_name => 'Fontli', :password => SECURE_TREE['default_pass'], :email => 'me@fontli.com')
