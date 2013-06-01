# Use command-line openssl enc tool directly to avoid discrepancies
module Encryptor

  OPTS = {
    :algo => 'aes-128-cbc',
    :key  => SECURE_TREE['encryption_key'],
    :iv   => SECURE_TREE['encryption_iv']
  }

  # takes an base64 encoded n encrypted text and decrypts it to plain string
  def self.decrypt(text64)
    `echo "#{text64}" | openssl enc -d -a | openssl enc -d -#{OPTS[:algo]} -K "#{OPTS[:key]}" -iv "#{OPTS[:iv]}" -nosalt`.strip
  end

  # takes a plain string and returns a base64 encoded n encrypted string
  def self.encrypt(text)
    `echo "#{text}" | openssl enc -e -#{OPTS[:algo]} -K "#{OPTS[:key]}" -iv "#{OPTS[:iv]}" -nosalt | openssl enc -e -a`.strip
  end
end
