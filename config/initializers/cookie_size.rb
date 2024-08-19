
# config/initializers/cookie_size.rb
module ActionDispatch
    class Cookies
      # Increase the MAX_COOKIE_SIZE to 8KB (8192 bytes)
      # MAX_COOKIE_SIZE = 4600
    end
  end