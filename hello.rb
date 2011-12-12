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

#helpers
helpers do

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'flipmode']
  end

end


# home
get '/' do
	@sections = Section.all(:parentid => nil)
	erb :home
end

# view a section
get '/s/:sectionname' do
	@section = Section.first(:name => params[:sectionname])
  	erb :section
end

# admin: home
get '/iambirchy' do
	protected!
	@sections = Section.all(:parentid => nil)
	erb :home_admin
end

#admin: section deletion
get '/iambirchy/s/delete/:id' do
	protected!
	@section = Section.get(params[:id])
	@section.destroy
	redirect '/iambirchy'
end

# admin: section creation
get '/iambirchy/s/add' do
	protected!
	erb :section_add
end

# admin: section create   
post '/iambirchy/s/create' do
	protected!
	section = Section.new(:name => params[:name])
  if section.save
    status 201 
  else
    status 412  
  end
  redirect '/iambirchy'
end
