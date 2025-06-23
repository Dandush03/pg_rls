# frozen_string_literal: true

module PgRls
  module ActiveSupport
    # Extensions to the String class
    module StringExt
      def sanitize_sql
        str = dup
        str.gsub!(/[[:space:]]+/, " ")
        str.strip!
        str.to_s
      end
    end
  end
end

String.include(PgRls::ActiveSupport::StringExt)
