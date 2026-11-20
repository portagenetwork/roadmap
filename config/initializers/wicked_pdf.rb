# frozen_string_literal: true

module DMPRoadmap
  # wkhtmlpdf configurations
  class Application < Rails::Application
    WickedPdf.configure do |config|
      config.exe_path = ENV.fetch('WICKED_PDF_PATH', '/usr/bin/wkhtmltopdf')
      config.proxy = ENV.fetch('WICKED_PDF_PROXY', '')
    end
  end
end
