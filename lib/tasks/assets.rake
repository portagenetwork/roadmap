# frozen_string_literal: true

namespace :assets do
  desc 'Copy third-party and static assets not served by the Rails asset pipeline to the public directory'
  task :copy do
    puts 'Executing assets:copy rake task...'

    # Bootstrap fonts
    source_dir = Dir.glob(Rails.root.join('node_modules', 'bootstrap', 'fonts', 'glyphicons-halflings-regular.*'))
    destination_dir = Rails.root.join('public', 'fonts', 'bootstrap')
    FileUtils.mkdir_p(destination_dir)
    FileUtils.cp_r(source_dir, destination_dir)

    # TinyMCE skins
    source_dir = Dir.glob(Rails.root.join('node_modules', 'tinymce', 'skins', 'ui', 'oxide'))
    destination_dir = Rails.root.join('public', 'tinymce', 'skins')
    FileUtils.mkdir_p(destination_dir)
    FileUtils.cp_r(source_dir, destination_dir)

    # DMP bilingual logo
    source_file = Rails.root.join('app', 'assets', 'images', 'dmp-logo-bil-large.png')
    destination_dir = Rails.root.join('public', 'images')
    FileUtils.mkdir_p(destination_dir)
    FileUtils.cp(source_file, destination_dir)
  end

  # Set assets:copy as an extension of assets:precompile
  Rake::Task['assets:precompile'].enhance do
    Rake::Task['assets:copy'].invoke
  end
end
