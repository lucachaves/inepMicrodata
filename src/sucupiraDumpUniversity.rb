require 'sequel'
require 'progress_bar'
require 'nokogiri'
require 'debugger'
require_relative 'sucupiraUniversities.rb'

bar = ProgressBar.new(@universities.size)
DB = Sequel.connect('mysql://root:luiz123@localhost/uniBrasil')
# DB.run "CREATE TABLE university (id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, sucupira_name VARCHAR(255) NOT NULL, simple_name VARCHAR(255), sigla VARCHAR(100), status INTEGER NOT NULL, city VARCHAR(255), longitude DOUBLE, latitude DOUBLE)"
university_db = DB[:university]

@universities.each{|code, uni|
	bar.increment!
	uni = Nokogiri::HTML.parse(uni).text
	uni.gsub(/\s+/, ' ')
	sigla = uni.scan(/\(.*\)/)[0]
	simple_name = uni.gsub(/\(.*\)/, '')
	simple_name.gsub!(/^\d+\s?/, '')
	university_db.insert(
		:id=> code.to_s.to_i, 
		:sucupira_name => Nokogiri::HTML.parse(uni).text, #decode html entity
		:status => 0,
		:simple_name => simple_name,
		:sigla => sigla
	)
}