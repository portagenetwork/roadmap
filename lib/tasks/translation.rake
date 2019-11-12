namespace :translation do

  desc "Backup Translations to a file"
  task backup: :environment do
    # Structure for this?
    {obj_type: []}
    dat = {}
    # Backup dmptemplate_translations table
    dat[:dmptemplate] = []
    Dmptemplate.all.each do |temp|
       temp_dat = {
        id: temp.id,
        locale: temp.locale,
        title: temp.title,
        description: temp.description,
        translations: [],
      }
      temp.dmptemplate_translations.all.each do |trans|
        temp_dat[:translations] << {
          locale: trans.locale,
          title: trans.title,
          description: trans.description,
        }
      end
      dat[:dmptemplate] << temp_dat
    end
    # Backup guidance_translations
    dat[:guidance] = []
    Guidance.all.each do |g|
      g_dat = {
        id: g.id,
        text: g.text,
        translations: []
      }
      g.guidance_translations.all.each do |trans|
        g_dat[:translations] << {
          locale: trans.locale,
          text: trans.text,
        }
      end
      dat[:guidance] << g_dat
    end
    # backup phase_translations
    dat[:phase] = []
    Phase.all.each do |p|
      p_dat = {
        id: p.id,
        title: p.title,
        description: p.description,
        translations: [],
      }
      p.phase_translations.all.each do |trans|
        p_dat[:translations] << {
          locale: trans.locale,
          title: trans.title,
          description: trans.description,
        }
      end
      dat[:phase] << p_dat
    end
    # Backup QuestionFormat Translations
    dat[:question_format] = []
    QuestionFormat.all.each do |qf|
      qf_dat = {
        id: qf.id,
        title: qf.title,
        description: qf.description,
        translations: [],
      }
      qf.question_format_translations.all.each do |trans|
        qf_dat[:translations] << {
          locale: trans.locale,
          title: trans.title,
          description: trans.description,
        }
      end
      dat[:question_format] << qf_dat
    end
    # Backup QuestionTranslations
    dat[:question] = []
    Question.all.each do |q|
      q_dat = {
        id: q.id,
        text: q.text,
        guidance: q.guidance,
        translations: [],
      }
      q.question_translations.all.each do |trans|
        q_dat[:translations] << {
          locale: trans.locale,
          text: trans.text,
          guidance: trans.guidance,
        }
      end
      dat[:question] << q_dat
    end
    # backup section_translations
    dat[:section] = []
    Section.all.each do |s|
      s_dat = {
        id: s.id,
        title: s.title,
        description: s.description,
        translations: [],
      }
      s.section_translations.all.each do |trans|
        s_dat[:translations] << {
          locale: trans.locale,
          title: trans.title,
          description: trans.description,
        }
      end
      dat[:section] << s_dat
    end
    # backup version_translations
    dat[:version] = []
    Version.all.each do |v|
      v_dat = {
        id: v.id,
        title: v.title,
        description: v.description,
        translations: [],
      }
      v.version_translations.all.each do |trans|
        v_dat[:translations] << {
          locale: trans.locale,
          title: trans.title,
          description: trans.description,
        }
      end
      dat[:version] = []
    end
    File.write("/tmp/dat/translations.json", JSON.dump(dat))
  end
end
