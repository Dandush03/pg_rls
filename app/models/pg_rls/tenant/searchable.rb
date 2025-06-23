# frozen_string_literal: true

module PgRls
  class Tenant
    # Searchable Class
    class Searchable
      SEARCH_METHOD_BY_COLUMN_TYPE = PgRls::Tenant.columns.each_with_object({}) do |column, hash|
        type = column.sql_type_metadata.type
        hash[type] ||= []
        hash[type] << column.name
      end

      def self.by_rls_object(tenant)
        case tenant
        when Tenant then tenant
        when String, Symbol, Integer then Searchable.by_rls_methods(tenant)
        when PgRls.main_model then tenant.becomes(Tenant)
        else raise PgRls::Error::InvalidSearchInput, "Invalid search input: #{tenant}"
        end
      end

      def self.by_rls_methods(search_input)
        new(search_input).search_methods.each do |search_method|
          tenant = PgRls::Tenant.find_by(search_method => search_input)
          return tenant if tenant.present?
        end

        raise PgRls::Error::TenantNotFound, "No tenant found for #{search_input}"
      end

      def initialize(search_input)
        @search_input = search_input
      end

      def search_methods
        SEARCH_METHOD_BY_COLUMN_TYPE[target_type] || []
      end

      private

      attr_reader :search_input

      def target_type
        case search_input
        when Integer then :integer
        when String, Symbol then target_type_by_string
        else raise PgRls::Error::InvalidSearchInput, "Invalid search input: #{search_input}"
        end
      end

      def target_type_by_string
        case search_input
        when /\A\d+\z/ then :integer
        when /\A[0-9a-fA-F\-]{36}\z/ then :uuid
        else :string
        end
      end
    end
  end
end
