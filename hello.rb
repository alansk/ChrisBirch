require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'carrierwave'
require 'carrierwave/datamapper'
require 'rmagick'

DataMapper.setup(:default, ENV['DATABASE_URL'])

class SectionUploader < CarrierWave::Uploader::Base
	include CarrierWave::RMagick
    
    version :icon do
      process :resize_to_fill => [125,125]
    end
    
	storage :file
end

class ItemUploader < CarrierWave::Uploader::Base
	include CarrierWave::RMagick

    
    version :expand_mobile do
      process :resize_to_fill => [250,250]
    end
    
    version :expand_desk do
      process :resize_to_fill => [500,500]
    end
    
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
  property :description,    String
  property :sectionid, 		Integer
  property :iconimg, 		String, 		:auto_validation => false
  mount_uploader :iconimg, 	SectionUploader
  property :expandimg, 		String, 		:auto_validation => false
  mount_uploader :expandimg, 	ItemUploader
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
	@title = 'Chris Birch : Business Man'
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

# view an item
get '/s/:sectionname/i/:title' do
	@title = 'Chris Birch : ' + params[:sectionname] + ' : ' + params[:title]
	@section = Section.first(:name => params[:sectionname])
	@item = Item.first(:sectionid => params[:id], :title => params[:title])
	@itemdetail = ItemDetail.first(:itemid => @item.id)
  	erb :item
end

# admin: home
get '/iambirchy/?' do
	protected!
	@title = 'Chris Birch : Admin'
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
	@title = 'Chris Birch : Admin'
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
	@title = 'Chris Birch : Admin'
	erb :item_add
end

# admin: item create   
post '/iambirchy/i/create' do
	protected!
	item = Item.new
	item.title = params[:title]
	item.description = params[:description] 
	item.sectionid = params[:sectionid]
	item.iconimg = params[:iconimg]
	item.expandimg = params[:expandimg]
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
	@title = 'Chris Birch : Admin'
	@section = Section.get(params[:id])
	@items = Item.all(:sectionid => params[:id])
  	erb :section_edititems
end

# admin: edit item
get '/iambirchy/i/edit/:id' do
	@title = 'Chris Birch : Admin'
	@item = Item.get(params[:id])
  	erb :item_edit
end