# frozen_string_literal: true

# Helper methods for displaying Identifiers
module IdentifierHelper
  def id_for_display(id:, with_scheme_name: true)
    return _('None defined') if id.new_record? || id.value.blank?

    without = id.value_without_scheme_prefix
    prefix = with_scheme_name ? "#{id.identifier_scheme.description}: " : ''
    return prefix + id.value unless without != id.value && !without.starts_with?('http')

    link_to "#{prefix} #{without}", id.value, class: 'has-new-window-popup-info'
  end

  def render_org_identifier(presenter:, scheme:, with_scheme_name: false)
    id = presenter.id_for_scheme(scheme: scheme)
    content_tag(:div, class: 'row') do
      content_tag(:div, class: 'form-group col-xs-10') do
        content_tag(:span, "#{scheme.description}: ", class: 'bold') +
          id_for_display(id: id, with_scheme_name: with_scheme_name)
      end
    end
  end
end
