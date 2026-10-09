# frozen_string_literal: true

# Helpers for selecting API versions and OAuth scopes in Doorkeeper forms.
module DoorkeeperApiHelper
  V2 = 'v2'
  COMMON_MADMP = 'common_madmp'
  V2_READ_SCOPE = 'v2_read'
  V2_WRITE_SCOPE = 'v2_write'
  COMMON_MADMP_READ_SCOPE = 'common_madmp_read'
  COMMON_MADMP_WRITE_SCOPE = 'common_madmp_write'

  # Every API offers the same access levels; only the scope names differ.
  API_SCOPES = {
    V2 => { read: V2_READ_SCOPE, write: V2_WRITE_SCOPE },
    COMMON_MADMP => { read: COMMON_MADMP_READ_SCOPE, write: COMMON_MADMP_WRITE_SCOPE }
  }.freeze

  API_CHOICES = API_SCOPES.transform_values do |scopes|
    { 'Read' => scopes[:read], 'Read + write' => "#{scopes[:read]} #{scopes[:write]}" }
  end.freeze

  API_DEFAULT_SCOPES = API_SCOPES.transform_values { |scopes| scopes[:read] }.freeze

  def api_versions
    [V2, COMMON_MADMP]
  end

  def api_scope_options_for(version)
    API_CHOICES.fetch(version.to_s)
  end

  def api_version_label(version)
    version.to_s == COMMON_MADMP ? 'Common MaDMP' : V2
  end

  def api_default_scope_for(version)
    API_DEFAULT_SCOPES[version.to_s]
  end

  def application_api_selection(application)
    scopes = application.scopes.to_a
    api_version = selected_api_for(scopes)

    {
      api_version: api_version,
      scope: selected_scope_for(scopes, api_version)
    }
  end

  def selected_api_for(scopes)
    Array(scopes).any? { |scope| scope.start_with?('common_madmp_') } ? COMMON_MADMP : V2
  end

  # Write implies read, so write-only access is normalized to read + write.
  def selected_scope_for(scopes, api_version)
    api_scopes = API_SCOPES.fetch(api_version.to_s)
    scopes = Array(scopes)

    if scopes.include?(api_scopes[:write])
      API_CHOICES[api_version.to_s]['Read + write']
    elsif scopes.include?(api_scopes[:read])
      api_scopes[:read]
    else
      api_default_scope_for(api_version)
    end
  end
end
