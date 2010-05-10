# Maintains a hash in specified order when retrieving keys/values
module RuportReportBuilderUtil
  class OrderedHash < Hash
    def initialize
      @keys = []
    end

    def []=(key, val)
      @keys << key
      super
    end
  
    def keys
      @keys
    end
  
    def values
      result = []
      each_value{|v| result << v}
      result
    end

    def delete(key)
      @keys.delete(key)
      super
    end

    def each
      @keys.each { |k| yield k, self[k] }
    end

    def each_key
      @keys.each { |k| yield k }
    end

    def each_value
      @keys.each { |k| yield self[k] }
    end
  
    alias_method :store, :[]=
    alias_method :each_pair, :each
  end
end