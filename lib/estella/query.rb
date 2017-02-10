module Estella
  class Query
    # Constructs a search query for ES
    attr_accessor :query
    attr_reader :params

    def initialize(params)
      @params = params

      @query = {
        _source: false
      }

      add_query
      add_field_boost
      add_filters
      add_excludes
      add_pagination
    end

    def must(filter)
      @query = {
        query: {
          filtered: {
            query: {
              bool: {
                must: [ filter ]
              }
            }
          }
        }
      }.merge(query)
    end

    def exclude(filter)
      @query = {
        query: {
          filtered: {
            query: {
              bool: {
                must_not: [ filter ]
              }
            }
          }
        }
      }.merge(query)
    end

    def query_definition
      {
        multi_match: {
          type: 'most_fields',
          fields: term_search_fields,
          query: params[:term]
        }
      }
    end

    def field_factors
      Estella::Analysis::DEFAULT_FIELD_FACTORS
    end

    private

    def add_pagination
      query[:size] = params[:size] if params[:size]
      query[:from] = params[:from] if params[:from]
    end

    def add_query
      if params[:term] && params[:indexed_fields]
        # fulltext search across all string fields
        @query = {
          query: {
            function_score: {
              query: query_definition
            }
          }
        }.merge(query)
      else
        @query = {
          query: {
            filtered: {
              query: {
                match_all: {}
              }
            }
          }
        }.merge(query)
      end
    end

    def add_field_boost
      boost = params[:boost]
      return unless boost

      query[:query][:function_score][:field_value_factor] = {
        field: boost[:field],
        modifier: boost[:modifier],
        factor: boost[:factor]
      }

      max = boost[:max]
      return unless max
      query[:query][:function_score][:max_boost] = max
    end

    # search all analysed string fields by default
    # boost them by factor if provided
    def term_search_fields
      params[:indexed_fields]
        .select { |_, opts| opts[:type].to_s == 'string' }
        .reject { |_, opts| opts[:analysis].nil? }
        .map do |field, opts|
          opts[:analysis].map do |analyzer|
            factor = field_factors[analyzer] * opts.fetch(:factor, 1.0)
            "#{field}.#{analyzer}^#{factor}"
          end
        end
        .flatten
    end

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
