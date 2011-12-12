require 'rubygems'
require 'sinatra'
require 'data_mapper'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class Section
  include DataMapper::Resource  
  property :id,           Serial
  property :name,         String
  property :parentid, 	Integer
end

DataMapper.auto_upgrade!

# home
get '/' do
	@sections = Section.all(:parentid => nil)
	erb :home
end

# view a section
get '/s/:sectionname' do
  @section = Section.get(:name => params[:sectionname])
  erb :section
end

# admin
get '/iambirchy' do
	@sections = Section.all(:parentid => nil)
	erb :home_admin
end

# view create section page
get '/s/creation' do
  erb :section_add
end
