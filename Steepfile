# frozen_string_literal: true

D = Steep::Diagnostic

target :pg_rls do
  signature "sig"

  check "lib"
  ignore "lib/pg_rls/active_record/test_databases.rb"

  # library "pathname"              # Standard libraries
  # library "strong_json"           # Gems

  # configure_code_diagnostics(D::Ruby.default)      # `default` diagnostics setting (applies by default)
  configure_code_diagnostics(D::Ruby.strict) # `strict` diagnostics setting
  # configure_code_diagnostics(D::Ruby.lenient)      # `lenient` diagnostics setting
  # configure_code_diagnostics(D::Ruby.silent)       # `silent` diagnostics setting
  configure_code_diagnostics do |hash| # You can setup everything yourself
    hash[D::Ruby::UnexpectedSuper] = :hint
  end
end

# target :test do
#   signature "sig", "sig-private"
#
#   check "test"
#
#   # library "pathname"              # Standard libraries
# end
