# frozen_string_literal: true

# Shared behavior for controllers that render a title-derived PDF filename
# and a standard wkhtmltopdf footer (used by PlanExportsController and
# PlanSnapshotsController).
module PdfExportable
  extend ActiveSupport::Concern

  # wkhtmltopdf behavior is based on the OS so force the zoom level
  # See 'Gotchas' section of https://github.com/mileszs/wicked_pdf
  PDF_ZOOM = 0.78125

  private

  # Sanitizes a title into a safe filename, optionally appending a suffix
  # (e.g. a version number) before the file extension is applied by the caller.
  def sanitized_file_name(title, suffix: nil)
    # Sanitize bad characters and replace spaces with underscores
    ret = title.to_s.strip.gsub(/\s+/, '_')
    ret = ret.gsub('&amp;', '&')
    ret = ret.delete('"')
    ret = ActiveStorage::Filename.new(ret).sanitized
    # limit the filename length to 100 chars. Windows systems have a MAX_PATH allowance
    # of 255 characters, so this should provide enough of the title to allow the user
    # to understand which DMP it is and still allow for the file to be saved to a deeply
    # nested directory
    ret = ret[0, 100]
    suffix.present? ? "#{ret}#{suffix}" : ret
  end

  # Builds the standard footer hash shared by plan and snapshot PDF exports.
  # `extra` allows callers to merge in options that vary (e.g. `spacing`).
  def pdf_footer(message:, extra: {})
    {
      center: message,
      font_size: 8,
      right: _('[page] of [topage]'),
      encoding: 'utf8'
    }.merge(extra)
  end
end
