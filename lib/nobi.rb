require 'base64'
require 'openssl'

module Nobi
  BadData = Class.new(StandardError)
  BadSignature = Class.new(BadData)
  SignatureExpired = Class.new(BadData)
  BadTimeSignature = Class.new(BadSignature)

  module Utils
    def self.base64_encode(string)
      Base64.urlsafe_encode64(string).gsub(/=+$/, '')
    end

    def self.base64_decode(string)
      Base64.urlsafe_decode64(string + '=' * (-string.length % 4))
    end

    def self.int_to_bytes(num)
      raise ArgumentError unless num >= 0

      rv = []

      while num > 0
        rv << (num & 0xff).chr
        num >>= 8
      end

      return rv.reverse.join
    end

    def self.bytes_to_int(bytes)
      bytes.each_byte.inject(0) do |acc, byte|
        acc << 8 | byte
      end
    end

    def self.constant_time_compare(val1, val2)
      return false unless val1.length == val2.length

      cmp = val2.bytes.to_a
      result = 0

      val1.bytes.each_with_index do |char, index|
        result |= char ^ cmp[index]
      end

      return result == 0
    end

    def self.rsplit(str, sep)
      if str =~ /\A(.*)#{Regexp.escape(sep)}([^#{Regexp.escape(sep)}]+)\z/
        return $1, $2
      end
    end
  end

  class HMACAlgorithm
    def initialize(digest_method)
      @digest_method = digest_method
    end

    def signature(key, value)
      OpenSSL::HMAC.digest(@digest_method, key, value)
    end
  end

  class Signer
    def initialize(secret,
      salt: 'nobi.Signer',
      sep: '.',
      digest_method: 'sha1')

      @secret = secret
      @salt = salt
      @sep = sep
      @algorithm = HMACAlgorithm.new(digest_method)
    end

    def sign(value)
      '%s%s%s' % [value, @sep, signature(value)]
    end

    def unsign(value)
      if not value.include?(@sep)
        raise BadSignature, 'No "%s" found in value' % @sep
      end

      value, sig = Utils.rsplit(value, @sep)

      if Utils.constant_time_compare(sig, signature(value))
        return value
      end

      raise BadSignature, 'Signature "%s" does not match' % sig
    end

    def derive_key
      @algorithm.signature(@secret, @salt)
    end

    def signature(value)
      key = derive_key
      sig = @algorithm.signature(key, value)

      Utils.base64_encode(sig)
    end
  end

  class TimestampSigner < Signer
    # 2011/01/01 in UTC
    EPOCH = 1293840000

    def get_timestamp
      Time.now.utc.to_f - EPOCH
    end

    def timestamp_to_datetime(ts)
      Time.at(ts + EPOCH).utc
    end

    def sign(value)
      timestamp = Utils.base64_encode(Utils.int_to_bytes(get_timestamp.to_i))
      value = '%s%s%s' % [value, @sep, timestamp]

      '%s%s%s' % [value, @sep, signature(value)]
    end

    def unsign(value, max_age: nil, return_timestamp: nil)
      sig_error = nil
      result = ''

      begin
        result = super(value)
      rescue BadSignature => e
        sig_error = e
      end

      if not result.include?(@sep)
        if sig_error
          raise sig_error
        else
          raise BadTimeSignature, 'timestamp missing'
        end
      end

      value, timestamp = Utils.rsplit(result, @sep)

      timestamp = Utils.bytes_to_int(Utils.base64_decode(timestamp))

      if max_age
        age = get_timestamp - timestamp

        if age > max_age
          raise SignatureExpired, 'Signature age %s > %s seconds' % [age, max_age]
        end
      end

      if return_timestamp
        return value, timestamp_to_datetime(timestamp)
      else
        return value
      end
    end
  end
end
