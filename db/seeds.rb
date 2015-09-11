# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

user = User.where(email: 'cavneb@gmail.com').first_or_initialize
user.first_name = 'Eric'
user.last_name = 'Berry'
user.phone = '8015804496'
user.password = 'password'
user.password_confirmation = 'password'
user.role = 'admin'
user.save!

#
# User.where(email: 'amberry202@gmail.com').first_or_create(
#   first_name: 'Amber',
#   last_name: 'Berry',
#   phone: '8013721572',
#   password: 'password',
#   password_confirmation: 'password',
#   role: 'customer'
# )

Product.delete_all
Product.create! name: '$18 per lesson', price: 18.0, quantity: 1, active: true
Product.create! name: '$15 per lesson for 30 lessons', price: 450.0, quantity: 30, active: true
Product.create! name: '$15 per lesson for 10 lessons', price: 150.0, quantity: 10, active: false


