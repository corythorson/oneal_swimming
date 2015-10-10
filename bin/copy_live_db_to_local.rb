#!/usr/bin/env ruby

require 'json'
require 'httparty'

TOKEN = File.read("/Users/eberry/.cloud66/token").strip
STACK_ID = '4c51197395b11e1bcd9bb9acad267e92'

headers = { "Authorization" => "Bearer #{TOKEN}" }

# Get backups
request = HTTParty.get("https://app.cloud66.com/api/3/stacks/#{STACK_ID}/backups.json", headers: headers)
response = request.response
resp = JSON.parse(response.body)
backup_id = resp['response'][0]['id']

# Get backup files
request = HTTParty.get("https://app.cloud66.com/api/3/stacks/#{STACK_ID}/backups/#{backup_id}/files.json", headers: headers)
response = request.response
resp = JSON.parse(response.body)
file_id = resp['response'][0]['id']

# Get backup file url
request = HTTParty.get("https://app.cloud66.com/api/3/stacks/#{STACK_ID}/backups/#{backup_id}/files/#{file_id}.json", :headers => headers)
response = request.response
resp = JSON.parse(response.body)

public_url = resp['response']['public_url']

puts "Download URL: #{public_url}"
