# constructs a search query for ElasticSearch
module Estella
  module Queries
    class Query
      attr_accessor :query
      attr_reader :params

      def initialize(params)
        @params = params
        @query = {
          _source: false
        }
      end
    end
  end
end
