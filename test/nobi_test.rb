require File.expand_path('../lib/nobi', File.dirname(__FILE__))
require 'cutest'

scope do
  setup do
    Nobi::Signer.new('foo')
  end

  test 'sign + unsign' do |s|
    assert_equal 'bar', s.unsign(s.sign('bar'))
  end

  test 'sign + unsign an int' do |s|
    assert_raise TypeError do
      s.sign(1)
    end
  end

  test 'no signature' do |s|
    assert_raise Nobi::BadSignature do
      s.unsign('nosep')
    end
  end

  test 'bad signature' do |s|
    assert_raise Nobi::BadSignature do
      s.unsign('bar.whatever')
    end
  end
end

scope do
  setup do
    Nobi::TimestampSigner.new('foo')
  end

  test 'sign + unsign' do |ts|
    assert_equal 'bar', ts.unsign(ts.sign('bar'))
  end

  test 'sign + unsign an int' do |ts|
    assert_equal '1', ts.unsign(ts.sign(1))
  end

  test 'unsign return_ timestamp' do |ts|
    time = Time.now.utc
    signed = ts.sign('bar')

    value, timestamp = ts.unsign(signed, return_timestamp: true)

    assert_equal 'bar', value

    # Because we can't make the exact time down to the fractional second,
    # we need to compare the time on an int level.
    assert_equal time.to_i, timestamp.to_i
  end

  test 'signature expired' do |ts|
    signed = ts.sign('bar')

    sleep 0.09

    assert_raise Nobi::SignatureExpired do
      ts.unsign(signed, max_age: 0.1)
    end
  end
end
