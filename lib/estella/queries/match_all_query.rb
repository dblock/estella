module Estella
  module Queries
    class MatchAllQuery < Query
      def initialize(params)
        super(params)

        @query = {
          query: {
            match_all: {}
          }
        }.deep_merge(query)

        add_filters
        add_excludes
      end

      def must(filter)
        @query = {
          filter: {
            bool: {
              must: [filter]
            }
          }
        }.deep_merge(query)
      end

      def exclude(filter)
        @query = {
          filter: {
            bool: {
              must_not: [filter]
            }
          }
        }.deep_merge(query)
      end

      private

      def add_filters
        indexed_fields = params[:indexed_fields]
        return unless indexed_fields
        indexed_fields.each do |field, opts|
          next unless opts[:filter] && params[field]
          must(term: { field => params[field] })
        end
      end

      def add_excludes
        exclude = params[:exclude]
        return unless exclude
        exclude.each do |k, v|
          exclude(term: { k => v })
        end
      end
    end
  end
end
