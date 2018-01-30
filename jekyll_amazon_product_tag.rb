#
# Liquid tag to show amazon product previews (with locally cached images) in blog posts 
# GitHub: https://github.com/aleks/jekyll_amazon_product_tag
#
require 'vacuum'
require 'yaml/store'
require 'hash_dot'

class Product
  def initialize(item_id)
    @item_id = item_id
    @store = YAML::Store.new('products/products.yml')
    config = Jekyll.configuration({})['amazon_product']
    request ||= Vacuum.new('DE')
    request.configure(
      aws_access_key_id: config['aws_access_key_id'],
      aws_secret_access_key: config['aws_secret_access_key'],
      associate_tag: config['associate_tag']
    )

    @response = request.item_lookup(
      query: {
        'ItemId' => @item_id,
        'ResponseGroup' => 'Images,ItemAttributes,OfferFull,EditorialReview'
      }
    )
    @response = @response.to_h
  end

  def item
    @response['ItemLookupResponse']['Items']['Item']
  end

  def item_attributes
    item['ItemAttributes']
  end

  def url
    item['DetailPageURL']
  end

  def title
    item_attributes['Title']
  end

  def description
    if item['EditorialReviews']
      item['EditorialReviews']['EditorialReview']['Content']
    end
  end

  def author
    item_attributes['Author'] || item_attributes['Brand']
  end

  def isbn
    item_attributes['ISBN']
  end

  def number_of_pages
    item_attributes['NumberOfPages']
  end

  def add_to_wishlist
    item['ItemLinks']['ItemLink'][0]['URL']
  end

  def price
    item['Offers']['Offer']['OfferListing']['Price']['FormattedPrice']
  end

  def image_path(size)
    "products/#{@item_id}-#{size}.jpg"
  end

  def store_images
    open(image_path('large'), 'wb'){ |f| f << open(item['LargeImage']['URL']).read }
  end

  def save
    @store.transaction do
      @store[@item_id.to_sym] = {
        created_at: Time.now,
        title: title,
        url: url,
        author: author,
        isbn: isbn,
        number_of_pages: number_of_pages,
        price: price,
        large_image_url: '/' + image_path('large'),
        add_to_wishlist: add_to_wishlist,
        description: description
      }

      @store.commit
    end

    store_images
  end
end

module Jekyll
  class RenderTimeTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      item_id = text.strip
      @store = YAML::Store.new('products/products.yml')
      @product = get_product(item_id)
    end

    def fetch_product(item_id)
      @store.transaction do
        @store.fetch(item_id.to_sym, :no_product_found)
      end
    end

    def get_product(item_id)
      if fetch_product(item_id) == :no_product_found
        product = Product.new(item_id)
        product.save
        return product
      else
        fetch_product(item_id).to_dot
      end
    end

    def render(context)
      content = <<-html
<div class="product">
  <div class="product-image">
    <img src="#{@product.large_image_url}" alt="#{@product.title}">
  </div>
  <div class="product-info">
    <h4 class="product-title"><a href="#{@product.url}" target="_blank">#{@product.title}</a></h4>
    <p class="product-author">#{@product.author}</p>
    <p class="product-price">#{@product.price} <span class="product-price-description">(Zum Zeitpunkt der Veröffentlichung)</span></p>
  </div>
  <div class="clearfix"></div>
</div>
      html
      return content
    end
  end
end

Liquid::Template.register_tag('amazon_product', Jekyll::RenderTimeTag)
