import getConstant from '../utils/constants';
import { isUndefined, isObject } from '../utils/isType';
import { Tinymce } from '../utils/tinymce.js';

$(() => {
  const form = $('.research_output_form');

  if (!isUndefined(form) && isObject(form)) {
    Tinymce.init({ selector: '#research_output_description' });
  }

  // DOI Verification & Redirect to New Form
  $('body').on('click', '#btn_fetch_doi', (e) => {
    e.preventDefault();
    const button = $(e.currentTarget);
    const inputField = $('#doi_lookup_input');
    const statusText = $('#doi_lookup_status');
    
    const doi = inputField.val().trim();
    const planId = button.data('plan-id');

    if (!doi) {
      statusText.removeClass('hidden text-success').addClass('text-danger').text('Please enter a DOI string.');
      return;
    }

    button.prop('disabled', true).text('Verifying...');
    statusText.removeClass('hidden text-danger text-success').addClass('text-muted').text('Validating identifier with DataCite...');

    $.ajax({
      url: `/plans/${planId}/research_outputs/fetch_doi`,
      method: 'GET',
      data: { doi: doi },
      dataType: 'json'
    }).done((data) => {
      statusText.removeClass('text-muted text-danger').addClass('text-success').text('DOI Verified! Redirecting to form...');
      
      // Dynamic browser redirection to the standard "New" view layout route
      window.location.href = `/plans/${planId}/research_outputs/new?prefill_doi=${encodeURIComponent(doi)}`;
    }).fail((xhr) => {
      button.prop('disabled', false).text('Fetch & Add');
      const response = xhr.responseJSON;
      const errorMsg = response && response.error ? response.error : 'Could not retrieve metadata for this DOI.';
      statusText.removeClass('text-muted text-success').addClass('text-danger').text(errorMsg);
    });
  });

  // Expands/Collapses the search results 'More info'/'Less info' section
  $('body').on('click', '.modal-search-result .more-info a.more-info-link', (e) => {
    e.preventDefault();
    const link = $(e.target);

    if (link.length > 0) {
      const info = $(link).siblings('div.info');

      if (info.length > 0) {
        if (info.hasClass('hidden')) {
          info.removeClass('hidden');
          link.text(`${getConstant('LESS_INFO')}`);
        } else {
          info.addClass('hidden');
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
