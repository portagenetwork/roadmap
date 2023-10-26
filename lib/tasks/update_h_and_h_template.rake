# frozen_string_literal: true

namespace :h_and_h_templates do
  desc 'Update Portage Template for Research in History and the Humanities fields from French to English'
  task fix_translations: :environment do
    # get all relevant template ids
    template_title = 'Portage Template for Research in History and the Humanities'
    template_locale = 'en-CA'
    template_ids = Template.where(title: template_title, locale: template_locale).pluck(:id)
    puts "The following Templates were gathered for this task (ids): #{template_ids}"

    # get all phase one and phase two ids for this template
    phase_one_ids = Phase.where(template_id: template_ids, number: 1).pluck(:id)
    phase_two_ids = Phase.where(template_id: template_ids, number: 2).pluck(:id)

    # get all question_ids for the 'Sharing and Reuse' section of phase one
    sharing_and_reuse = 'Sharing and Reuse'
    phase_one_sharing_and_reuse_section_ids = Section.where(phase_id: phase_one_ids,
                                                            title: sharing_and_reuse).pluck(:id)
    sharing_and_reuse_question_ids = Question.where(section_id: phase_one_sharing_and_reuse_section_ids).pluck(:id)

    # get all question_ids for the 'Preservation' section of phase two
    preservation = 'Preservation'
    phase_two_preservation_section_ids = Section.where(phase_id: phase_two_ids, title: preservation).pluck(:id)
    preservation_question_ids = Question.where(section_id: phase_two_preservation_section_ids).pluck(:id)

    # update French sharing_and_reuse_questions to English
    # rubocop:disable Style/StringLiterals, Layout/LineLength
    french_sharing_and_reuse_question_text = 'D&eacute;crire la strat&eacute;gie de diffusion envisag&eacute;e pour faire conna&icirc;tre l&rsquo;existence du mat&eacute;riel de recherche aupr&egrave;s de ses publics.'
    english_sharing_and_reuse_question_text = 'english_sharing_and_reuse_question_text'
    sharing_and_reuse_questions = Question.where(id: sharing_and_reuse_question_ids,
                                                 text: french_sharing_and_reuse_question_text)
    puts "Phase 1 Sharing and Reuse Questions to be updated (ids): #{sharing_and_reuse_questions.pluck(:id)}"
    sharing_and_reuse_questions.update_all(text: english_sharing_and_reuse_question_text)
    puts "Phase 1 Sharing and Reuse Questions finished updated"

    # update French sharing_and_reuse_example_answer to English
    french_sharing_and_reuse_example_answer = "<span style=\"font-weight: 400;\"><strong>Exemple : </strong>Signalement dans un d&eacute;p&ocirc;t de donn&eacute;es de reconnu, attribution d&rsquo;un identifiant p&eacute;renne comme DOI - voir le </span><a href=\"https://zenodo.org/record/3862656/files/Dataset%20Identifiers%20Guide.pdf?download=1\"><span style=\"font-weight: 400;\">guide du projet FREYA</span></a><span style=\"font-weight: 400;\"> (</span><em><span style=\"font-weight: 400;\">lien en anglais</span></em><span style=\"font-weight: 400;\">), signalement dans les listes de diffusion et r&eacute;seaux sociaux.</span>"
    english_sharing_and_reuse_example_answer = 'english_sharing_and_reuse_example_answer'
    sharing_and_guidance_annotations_one = Annotation.where(question_id: sharing_and_reuse_question_ids,
                                                            text: french_sharing_and_reuse_example_answer)
    puts "Phase 1 Sharing and Reuse Example Answer Annotations to be updated (ids): #{sharing_and_guidance_annotations_one.pluck(:id)}"
    sharing_and_guidance_annotations_one.update_all(text: english_sharing_and_reuse_example_answer)
    puts "Phase 1 Sharing and Reuse Example Answer Annotations finished updated"

    # update French sharing_and_reuse_guidance to English
    french_sharing_and_reuse_guidance = "<p><span style=\"font-weight: 400;\">Pour optimiser la diffusion du mat&eacute;riel de recherche, suivre le plus possible les principes FAIR. L&rsquo;</span><a href=\"https://ardc.edu.au/resources/working-with-data/fair-data/fair-self-assessment-tool/\"><span style=\"font-weight: 400;\">Australian Research Data Commons</span></a><span style=\"font-weight: 400;\"> offre un outil d&rsquo;&eacute;valuation du respect de ces principes qui est tr&egrave;s facile d'utilisation (</span><em><span style=\"font-weight: 400;\">lien en anglais</span></em><span style=\"font-weight: 400;\">). Le Digital Curation Centre fournit un </span><a href=\"http://www.dcc.ac.uk/resources/how-guides/cite-datasets\"><span style=\"font-weight: 400;\">guide d&eacute;taill&eacute; sur la citation des donn&eacute;es</span></a><span style=\"font-weight: 400;\"> (tant num&eacute;riques que physiques; </span><em><span style=\"font-weight: 400;\">lien en anglais</span></em><span style=\"font-weight: 400;\">).<br /><br />Pour rendre le mat&eacute;riel r&eacute;cup&eacute;rable par d&rsquo;autres outils et le citer dans les publications savantes, publication d&rsquo;un article de donn&eacute;es dans une revue en libre acc&egrave;s comme <a href=\"https://brill.com/rdj\">Research Data Journal for the Humanities and Social Sciences</a> (<em>lien en anglais</em>).</span></p>\r\n<p><span style=\"font-weight: 400;\">Consulter au besoin une </span><a href=\"https://portagenetwork.ca/fr/outils-et-ressources/personnes-ressources-pour-la-gdr-dans-les-etablissements/\"><span style=\"font-weight: 400;\">personne ressource</span></a> <span style=\"font-weight: 400;\">ou contactez le Coordonnateur du PGD &agrave; </span><a href=\"mailto:support@portagenetwork.ca\"><span style=\"font-weight: 400;\">support@portagenetwork.ca</span></a>.</p>"
    english_sharing_and_reuse_guidance = 'english_sharing_and_reuse_guidance'
    sharing_and_guidance_annotations_two = Annotation.where(question_id: sharing_and_reuse_question_ids,
                                                            text: french_sharing_and_reuse_guidance)
    puts "Phase 1 Sharing and Reuse Guidance Annotations to be updated (ids): #{sharing_and_guidance_annotations_two.pluck(:id)}"
    sharing_and_guidance_annotations_two.update_all(text: english_sharing_and_reuse_guidance)
    puts "Phase 1 Sharing and Reuse Guidance annotations finished updated"

    # update French preservation_questions to English
    french_preservation_question_text = 'Des co&ucirc;ts sont-ils associ&eacute;s au choix du lieu de d&eacute;p&ocirc;t et &agrave; la pr&eacute;paration des donn&eacute;es?'
    english_preservation_question_text = 'english_preservation_question_text'
    preservation_questions = Question.where(id: preservation_question_ids, text: french_preservation_question_text)
    puts "Phase 1 Preservation Questions to be updated (ids): #{preservation_questions.pluck(:id)}"
    preservation_questions.update_all(text: english_preservation_question_text)
    puts "Phase 1 Preservation Questions finished updated"

    # update French preservation_guidance to English
    french_preservation_guidance = "<p><span style=\"font-weight: 400;\">La pr&eacute;paration du mat&eacute;riel de recherche pour son &eacute;ventuelle conservation implique une vari&eacute;t&eacute; de t&acirc;ches pouvant pr&eacute;senter des co&ucirc;ts qu&rsquo;il est pr&eacute;f&eacute;rable de budg&eacute;tiser dans la demande de financement. &Agrave; cette fin, un </span><a href=\"https://www.curationexchange.org/understand-your-costs/19-summary-of-cost-models\"><span style=\"font-weight: 400;\">mod&egrave;le de co&ucirc;ts</span></a><span style=\"font-weight: 400;\"> peut-&ecirc;tre utile ou simplement les rubriques de base du </span><a href=\"https://ukdataservice.ac.uk/media/622368/costingtool.pdf\"><span style=\"font-weight: 400;\">UK Data Service Costing Tool</span></a><span style=\"font-weight: 400;\"> (</span><em><span style=\"font-weight: 400;\">liens en anglais</span></em><span style=\"font-weight: 400;\">).</span></p>\r\n<p><span style=\"font-weight: 400;\">Int&eacute;grer cette estimation de co&ucirc;t dans la section </span><em><span style=\"font-weight: 400;\">Responsabilit&eacute;s et ressources</span></em><span style=\"font-weight: 400;\">.</span></p>\r\n<p><span style=\"font-weight: 400;\">Consulter au besoin une </span><a href=\"https://portagenetwork.ca/fr/outils-et-ressources/personnes-ressources-pour-la-gdr-dans-les-etablissements/\"><span style=\"font-weight: 400;\">personne ressource</span></a><span style=\"font-weight: 400;\"> ou contactez le Coordonnateur du PGD &agrave; </span><a href=\"mailto:support@portagenetwork.ca\"><span style=\"font-weight: 400;\">support@portagenetwork.ca</span></a><span style=\"font-weight: 400;\">.</span></p>"
    english_preservation_guidance = 'english_preservation_guidance'
    preservation_annotations = Annotation.where(question_id: preservation_question_ids,
                                                text: french_preservation_guidance)
    puts "Phase 1 Preservation Guidance Annotations to be updated (ids): #{preservation_annotations.pluck(:id)}"
    preservation_annotations.update_all(text: english_preservation_guidance)
    puts "Phase 1 Preservation Annotations finished updated"
    # rubocop:enable Style/StringLiterals, Layout/LineLength
  end
end
