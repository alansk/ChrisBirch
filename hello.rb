require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'carrierwave'
require 'carrierwave/datamapper'

DataMapper.setup(:default, ENV['DATABASE_URL'])

class ImageUploader < CarrierWave::Uploader::Base
	#include CarrierWave::MiniMagick
	storage :file
end

class Section
  include DataMapper::Resource  
  property :id,           Serial
  property :name,         String
  property :parentid, 	Integer
end

class Item
  include DataMapper::Resource  
  property :id,           	Serial
  property :title,       	String
  property :body,         	String
  property :sectionid, 		Integer
  property :file, 			String, 		:auto_validation => false
  mount_uploader :file, 	ImageUploader
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
	@title = 'Chris Birch : ' + params[:sectionname]
	@section = Section.first(:name => params[:sectionname])
	@items = Item.all(:sectionid => @section.id)
  	erb :section
end

# admin: home
get '/iambirchy/?' do
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

# admin: item creation
get '/iambirchy/i/add/:sectionid' do
	protected!
	erb :item_add
end

# admin: item create   
post '/iambirchy/i/create' do
	protected!
	item = Item.new
	item.title = params[:title]
	item.body = params[:body] 
	item.sectionid = params[:sectionid]
	item.file = params[:image]
	item.save
    redirect '/iambirchy'
end

# admin: item delete  
get '/iambirchy/i/delete/:id' do
	protected!
	@item = Item.get(params[:id])
	@item.destroy
	redirect '/iambirchy'
end

# admin: edit items in a section
get '/iambirchy/s/edititems/:id' do
	@section = Section.get(params[:id])
	@items = Item.all(:sectionid => params[:id])
  	erb :section_edititems
end
