require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'carrierwave'
require 'carrierwave/datamapper'
require 'RMagick'

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
  property :name_lower,   String
  property :name,         String
  property :parentid, 	Integer
  property :ordering, Integer
end

class Item
  include DataMapper::Resource  
  property :id,           	Serial
  property :title_lower,    String
  property :title,       	String
  property :description,    String
  property :sectionid, 		Integer
  property :url,			String
  property :iconimg, 		String, 		:auto_validation => false
  mount_uploader :iconimg, 	SectionUploader
  property :expandimg, 		String, 		:auto_validation => false
  mount_uploader :expandimg, 	ItemUploader
  property :ordering, Integer
end

class ItemDetail
	include DataMapper::Resource 
	property :id,           	Serial
  	property :itemid,      		Integer
  	property :body,				String
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
	@sections = Section.all(:parentid => nil, :order  => [:ordering.asc])
	erb :home
end

# view a section
get '/s/:sectionname/?' do
	@section = Section.first(:name_lower => params[:sectionname])
	@items = Item.all(:sectionid => @section.id, :order  => [:ordering.asc])
	if @items.count == 1
		redirect '/s/' + params[:sectionname] + '/i/' + @items.first.title
	end
	
	@title = 'Chris Birch : ' + @section.name
  	erb :section
end

# view an item
get '/s/:sectionname/i/:title/?' do
	@section = Section.first(:name_lower => params[:sectionname])
	@item = Item.first(:sectionid => @section.id, :title_lower => params[:title])
	@itemdetail = ItemDetail.first(:itemid => @item.id)
	if @itemdetail == nil and @item.url != nil
		redirect @item.url
	end
	@title = 'Chris Birch : ' + @section.name + ' : ' + @item.title
  	erb :item
end

# admin: home
get '/iambirchy/?' do
	protected!
	@title = 'Chris Birch : Admin'
	@sections = Section.all(:parentid => nil, :order  => [:ordering.asc])
	erb :home_admin
end

# admin: section ordering change
post '/iambirchy/s/ordering' do
	protected!
	sections = Section.all()
	sections.each do |section|
		key_order = 'order_' + section.id.to_s
		key_name = 'name_' + section.id.to_s
		section.name_lower = params[key_name].downcase 
		section.name = params[key_name]
		section.ordering = params[key_order]
		section.save
	end
	redirect '/iambirchy'
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
	section = Section.new(:name_lower => params[:name].downcase, :name => params[:name])
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
	item.title_lower = params[:title].downcase
	item.title = params[:title]
	item.description = params[:description] 
	item.url = params[:url]
	item.sectionid = params[:sectionid]
	item.iconimg = params[:iconimg]
	item.expandimg = params[:expandimg]
	item.save
    redirect '/iambirchy'
end

# admin: item ordering change
post '/iambirchy/s/:sectionname/ordering' do
	protected!
	section = Section.first(:name_lower => params[:sectionname])
	items = Item.all(:sectionid => section.id)
	items.each do |item|
		key = 'order_' + item.id.to_s
		item.ordering = params[key]
		item.save
	end
	redirect '/iambirchy/s/edititems/' + section.id.to_s
end

# admin: item edit  
put '/iambirchy/i/?' do
	protected!
	item = Item.get(params[:id])
	item.title_lower = params[:title].downcase
	item.title = params[:title]
	item.description = params[:description]
	item.url = params[:url]
	item.sectionid = params[:sectionid]
	if params[:iconimg] != nil
		item.iconimg = params[:iconimg]
	end
	if params[:expandimg] != nil
		item.expandimg = params[:expandimg]
	end
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

# admin: item add detail 
get '/iambirchy/i/add_detail/:itemid' do
	protected!
	erb :item_adddetail
end

post '/iambirchy/i/add_detail' do
	protected!
	itemdetail = ItemDetail.new
	itemdetail.itemid = params[:itemid]
	itemdetail.body = params[:body]
	itemdetail.save
	redirect '/iambirchy'
end

# admin: item edit detail  
get '/iambirchy/i/edit_detail/:itemid' do
	protected!
	@itemdetail = ItemDetail.first(:itemid => params[:itemid])
	erb :item_editdetail
end

put '/iambirchy/i/edit_detail' do
	protected!
	itemdetail = ItemDetail.get(params[:id])
	itemdetail.body = params[:body]
	itemdetail.save
	redirect '/iambirchy'
end

# admin: edit items in a section
get '/iambirchy/s/edititems/:id' do
	@title = 'Chris Birch : Admin'
	@section = Section.get(params[:id])
	@items = Item.all(:sectionid => params[:id], :order  => [:ordering.asc])
  	erb :section_edititems
end

# admin: edit item
get '/iambirchy/i/edit/:id' do
	@title = 'Chris Birch : Admin'
	@item = Item.get(params[:id])
	@sections = Section.all()
  	erb :item_edit
end