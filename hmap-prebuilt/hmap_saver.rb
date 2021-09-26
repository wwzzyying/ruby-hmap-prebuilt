require File.join(File.dirname(__FILE__), 'hmap_bucket.rb')
require File.join(File.dirname(__FILE__), 'MapFile.rb')

class HMapSaver
    include Utils
    attr_reader :string_table, :buckets, :headers
    
    def initialize
        @string_table = "\0"
        @buckets = []
        @headers = {}
    end
    
    def self.new_from_buckets(buckets)
        saver = new
        saver.add_to_buckets(buckets)
        saver
    end
    
    def add_to_buckets(buckets)
        buckets.each { |bucket| add_to_bucket(bucket) }
    end
    
    def add_to_bucket(buckets)
        # buckets 是每个头文件 key-value
        values = buckets.map { |key|
            if key.class == Hash
                add_to_headers(key.values.first)
            else
                add_to_headers(key)
            end
        }
        if buckets.first.include?("/")
            values.push(add_to_headers(buckets.first.split("/").last))
        else
            values.push(values[0])
        end
        bucket = HMapBucket.new(*values)
        bucket.uuid = Utils.string_downcase_hash(buckets.first)
        @buckets << bucket
    end
    
    def add_to_headers(key)
        if headers[key].nil?
            headers[key] = string_table.length
            add_to_string_table(key)
        end
        headers[key]
    end
    
    def add_to_string_table(str)
        @string_table += "#{Utils.safe_encode(str, 'ASCII-8BIT')}\0"
    end
    
    def write_to(path)
        MapFile.new(@string_table, @buckets).write(path)
    end
end
