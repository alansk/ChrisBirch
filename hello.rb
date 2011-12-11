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

@post = Section.create(
  :name      => "Ads"
)

get '/' do
	@section = Section.get(1)
  "Chris Birch: Business Man <br/> --- <br/> " + @section.name
end