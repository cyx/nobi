nobi
====

Requirements
------------

- Ruby 2.0


Ruby port of [itsdangerous][itsdangerous] python signer.

[itsdangerous]: http://pythonhosted.org/itsdangerous/

Examples
--------

Best two usecases:

1. Creating an activation link for users
2. Creating a password reset link

## Creating an activation link for users

```ruby
signer = Nobi::Signer.new('my secret')

# Let's say the user's ID is 101
signed = signer.sign('101')

# You can now email this url to your users!
url = "http://yoursite.com/activate/?key=%s" % signed
```

## Creating a password reset link
```ruby
signer = Nobi::TimestampSigner.new('my secret')

# Let's say the user's ID is 101
signed = signer.sign('101')

# You can now email this url to your users!
url = "http://yoursite.com/password-reset/?key=%s" % signed

# In your code, you can verify the expiration:
signer.unsign(signed, max_age: 86400) # 1 day expiration
```

## Installation

As usual, you can install it using rubygems.

```
$ gem install nobi
```
