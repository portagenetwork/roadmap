# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

Mime::Type.register(
  # The standard MIME type for RDA DMP Common v1.2
  'application/vnd.org.rd-alliance.dmp-common.v1.2+json',
  :rda_dmp_v12 # `:rda_dmp_v1_2` raises Rubocop Naming/VariableNumber offence
)
