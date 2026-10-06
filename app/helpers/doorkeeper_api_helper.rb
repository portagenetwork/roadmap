# frozen_string_literal: true

# Helpers for selecting API versions and OAuth scopes in Doorkeeper forms.
module DoorkeeperApiHelper
  SCOPE_OPTIONS = {
    'Read' => 'read',
    'Read and write' => 'read write'
  }.freeze

  def scope_options
    SCOPE_OPTIONS
  end

  def scope_option_checked?(application, value)
    current = application.scopes.to_s.split.sort
    current = ['read'] if current.empty? # default for new records

    current == value.split.sort
  end
end
