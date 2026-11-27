import getConstant from '../utils/constants';
import { isUndefined, isObject } from '../utils/isType';
import { Tinymce } from '../utils/tinymce';

const STATUS_CLASSES = 'd-none text-muted text-danger text-success';

$(() => {
  const form = $('.research_output_form');

  if (!isUndefined(form) && isObject(form)) {
    Tinymce.init({ selector: '#research_output_description' });
  }

  // Browsers can preserve the disabled button when restoring this page from
  // the back-forward cache, so reset it when the page is shown again.
  window.addEventListener('pageshow', (event) => {
    if (event.persisted) {
      $('#btn_prefill_doi')
        .prop('disabled', false)
        .text(getConstant('DOI_BUTTON_TEXT_DEFAULT'));
    }
  });

  // Toggle DOI form visibility
  $('body').on('click', '#btn_toggle_doi_form', (e) => {
    e.preventDefault();
    const panel = $('#doi_lookup_panel');

    panel.toggleClass('d-none');

    if (!panel.hasClass('d-none')) {
      $('#doi_lookup_input').focus();
    }
  });

  $('body').on('click', '#btn_prefill_doi', (e) => {
    e.preventDefault();
    const button = $(e.currentTarget);
    const inputField = $('#doi_lookup_input');
    const statusText = $('#doi_lookup_status');

    const doi = inputField.val().trim();
    const cleanDoi = doi.replace(/^https?:\/\/(?:dx\.)?doi\.org\//i, '');

    const prefillPath = button.data('prefill-path');

    // Helper for DRY-ing state updates
    const setLookupStatus = (type, message) => {
      statusText.removeClass(STATUS_CLASSES).addClass(type).text(message);
    };

    if (!doi) {
      setLookupStatus('text-danger', getConstant('DOI_VALIDATION_EMPTY'));
      return;
    }

    const modernDoiPattern = new RegExp(`^(?:${getConstant('DOI_MODERN_PATTERN')})$`, 'i');
    const oldDoiPattern = new RegExp(`^(?:${getConstant('DOI_OLD_PATTERN')})$`, 'i');

    if (!modernDoiPattern.test(cleanDoi) && !oldDoiPattern.test(cleanDoi)) {
      setLookupStatus('text-danger', getConstant('DOI_VALIDATION_INVALID'));
      return;
    }

    button.prop('disabled', true).text(getConstant('DOI_VALIDATION_VERIFYING'));
    setLookupStatus('text-muted', getConstant('DOI_VALIDATION_VERIFYING'));

    $.ajax({
      url: prefillPath,
      data: { prefill_doi: cleanDoi },
      dataType: 'json',
    }).done((result) => {
      if (inputField.val().trim() !== doi) {
        setLookupStatus('text-danger', getConstant('DOI_LOOKUP_CHANGED'));
        return;
      }

      const { metadata } = result;
      $('#research_output_title').val(metadata.title);
      $('#research_output_description').val(metadata.description);
      const editor = Tinymce.findEditorById('research_output_description');
      if (editor) editor.setContent(metadata.description || '');
      $('#research_output_release_date').val(metadata.release_date);
      $('#research_output_output_type').val(metadata.output_type);
      const other = metadata.output_type === 'other';
      $('.output-type-description').toggleClass('visually-hidden-focusable d-none', !other);
      $('#research_output_output_type_description').attr('aria-required', String(other));
      const fileDetailsSection = $('.file-details-section');
      fileDetailsSection.toggleClass('d-none', !result.byte_sizable);
      if (!result.byte_sizable) {
        fileDetailsSection.find('#research_output_file_size').val('');
      }
      setLookupStatus('text-success', getConstant('DOI_LOOKUP_SUCCESS'));
    }).fail((xhr) => {
      const message = xhr.responseJSON && xhr.responseJSON.error;
      setLookupStatus('text-danger', message || getConstant('DOI_LOOKUP_ERROR'));
    }).always(() => {
      button.prop('disabled', false).text(getConstant('DOI_BUTTON_TEXT_DEFAULT'));
    });
  });

  // Expands/Collapses the search results 'More info'/'Less info' section
  $('body').on('click', '.modal-search-result .more-info a.more-info-link', (e) => {
    e.preventDefault();
    const link = $(e.target);

    if (link.length > 0) {
      const info = $(link).siblings('div.info');

      if (info.length > 0) {
        if (info.hasClass('d-none')) {
          info.removeClass('d-none');
          link.text(`${getConstant('LESS_INFO')}`);
        } else {
          info.addClass('d-none');
          link.text(`${getConstant('MORE_INFO')}`);
        }
      }
    }
  });

  // Put the facet text into the modal search window's search box when the user
  // clicks on one
  $('body').on('click', '.modal-search-result a.facet', (e) => {
    const link = $(e.target);

    if (link.length > 0) {
      const textField = link.closest('.modal-body').find('input.autocomplete');

      if (textField.length > 0) {
        textField.val(link.text());
      }
    }
  });
});
