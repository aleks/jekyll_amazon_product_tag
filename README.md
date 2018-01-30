# jekyll_amazon_product_tag
Liquid tag to show amazon product previews (with locally cached images) in blog posts

## Install gems
```gem install vacuum hash_dot```

## Install plugin
Add `jekyll_amazon_product_tag.rb` to your `_plugins` folder.

## Create local cache folder

1. Create a new `products` directory in your jekyll root path.
2. Add an empty `products.yml` file to it.

Product images will be downloaded to this folder

## AWS credentials
Add your AWS credentials to your _config.yml
```
amazon_product:
  aws_access_key_id: 'ACCESS_KEY_ID'
  aws_secret_access_key: 'SECRET_ACCESS_KEY'
  associate_tag: 'ASSOCIATE_TAG'
```
## Add Product previews to your posts
Liquid Tag `{% amazon_product AMAZON_ID %}`

If the URL is `https://www.amazon.com/Practical-Object-Oriented-Design-Ruby-Addison-Wesley/dp/0321721330/` then `0321721330` will be the AMAZON_ID.
